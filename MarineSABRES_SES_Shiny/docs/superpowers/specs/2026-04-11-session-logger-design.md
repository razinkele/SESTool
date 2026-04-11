# Session Logger Design

**Status**: Approved 2026-04-11 (revision 2 after adversarial review)
**Replaces**: Sprint 4 Task 1 (M2 — `session_logging true;` in `shiny-server.conf`) which was reverted after Shiny Server open-source rejected the Pro-only directive and crash-looped production for ~4 minutes.

## Purpose

Give ops a minimum-viable observability signal for the MarineSABRES SES Toolbox running on laguna.ku.lt: **when did a session start, when did it end, and how long did it last.** One line per event, NDJSON, persisted across restarts.

This unlocks three workflows with essentially zero infrastructure cost:

1. **Post-crash forensics** — "session `sess_abc123...` started at 14:23, ended at 14:25, duration 120s" lets ops cross-reference the daemon log for that window.
2. **Load monitoring** — `cat sessions-*.jsonl | jq -r .ts | sort | uniq -c` gives session counts per time bucket without a metrics stack.
3. **User audit trail seed** — start/end events are the scaffolding future features (project-save logging, language-change logging) can hang onto by reusing the same log file.

Scope is deliberately "start small". No client IP (pure YAGNI, though also GDPR-conservative for a Horizon Europe project), no user agent, no per-action audit, no metrics endpoint.

## Non-goals

- **Not a crash detector**. `session$onSessionEnded` fires on clean disconnects but **NOT on daemon SIGKILL or abrupt worker crashes**. Sessions active at a hard daemon shutdown will leave a `session_start` event with no matching `session_end`. Consumers doing join/duration queries (e.g., `jq`) must handle orphans — tolerate unclosed starts, optionally cap duration at "daemon restart time" for analysis.
- **Not a replacement for Shiny Server Pro observability**. Those require a paid license and a non-OSS deployment.
- **Not a GDPR audit log**. No identifying fields are captured. See "Privacy" section.
- **Not a load-testing tool**. Use `shinyloadtest` for that.

## Privacy (GDPR)

Verified against `functions/session_isolation.R:22-42` on 2026-04-11. The `session_id` is generated as:

```
session_id <- paste0("sess_", substr(digest::digest(paste(timestamp, random_bytes, process_id, sep = "_"), algo = "sha256"), 1, 24))
```

Inputs to the hash: current wallclock timestamp, 16 random hex chars from `sample()`, and `Sys.getpid()`. **No IP, no HTTP headers, no client fingerprint, no user agent.** The logged session_id is purely derived from random + timing + process state, and is therefore anonymous data under GDPR Art. 4(1) — not even pseudonymous.

Safe to log the full 29-char ID. The original plan to truncate to 8 chars was rejected because `"sess_" + 3 hash chars` gives only 12 bits of correlation — useless for forensics.

## Architecture

One new file, two small modifications, one new test file, no new dependencies.

```
functions/session_logger.R   (new, ~90 lines)
    ├─ .session_log_env       (package-level env, caches resolved path)
    ├─ resolve_session_log_dir()
    ├─ build_session_log_path()
    ├─ log_session_start(session, i18n)
    └─ log_session_end(session_id, start_time)

global.R                     (1-line source() addition)
app.R                        (3-line wiring in server function, AFTER init_session_isolation)
tests/testthat/test-session-logger.R  (new, 5 unit tests)
```

### Components

**`resolve_session_log_dir()`** — Returns the writable directory where session log files live. Cached in a package-level env (`.session_log_env$dir`) so the resolve-and-test happens only once per R worker process, not per session.

Resolution order:
1. Attempt `dir.create("/var/log/shiny-server/marinesabres", recursive = TRUE, showWarnings = FALSE)` — idempotent; verified on laguna 2026-04-11 that `/var/log/shiny-server/` is owned `shiny:shiny` mode 755, so the shiny user running the Shiny worker CAN create and write subdirs.
2. `file.access(path, mode = 2) == 0` → return the canonical path (cached).
3. Fallback: `file.path(tempdir(), "marinesabres_sessions")`, same create-and-test pattern.
4. Last resort: return `NULL`. Downstream log functions treat `NULL` as "logging disabled, no-op".

**Note on cache staleness**: if the directory becomes unwritable mid-worker-lifetime (permissions revoked, disk unmounted), the cached path still points there and writes will fail. The outer `tryCatch` in `log_session_*` catches this silently, but ops would see nothing. **First-failure logging is at WARN level** (not DEBUG) so an `grep WARN /var/log/shiny-server.log` surfaces the issue. Subsequent failures log at DEBUG to avoid log spam.

**`build_session_log_path()`** — Composes `<resolved_dir>/sessions-<YYYY-MM-DD>.jsonl`. Called per event. Date uses **UTC** explicitly to avoid tz ambiguity at day boundaries:

```r
date_str <- format(Sys.time(), "%Y-%m-%d", tz = "UTC")
```

Do NOT wrap in `as.Date()` — the round-trip reintroduces local-tz parsing in `as.Date.character` and silently regresses the UTC fix. Single `format()` call is the correct form.

Date-based daily rotation is built into the filename; no cron or logrotate rule needed.

**JSON `NULL` field behavior note**: `jsonlite::toJSON(list(...), auto_unbox = TRUE)` **omits** `NULL` elements from the output entirely — it does NOT render them as `null`. Our guarded field extraction always returns strings (tryCatch defaults to `"en"`, etc.), so no NULLs reach the serializer in the current design. If future fields are added, remember that `NULL` will silently disappear from the record; use `NA` or a sentinel string if the field must be present.

**`log_session_start(session, i18n)`** — Writes a session_start NDJSON line:

```json
{"ts":"2026-04-11T22:45:13Z","event":"session_start","session_id":"sess_abc123def456789012345678","lang":"en","app_version":"1.11.0"}
```

Field sources:
- `ts` — `paste0(format(Sys.time(), "%Y-%m-%dT%H:%M:%S", tz = "UTC"), "Z")`. Explicit `"Z"` is appended rather than embedded in the format string to prevent the marker becoming a lie if the `tz` argument is ever changed.
- `session_id` — **full** `session$userData$session_id` (29 chars). Set by `init_session_isolation()` at `functions/session_isolation.R:64` which runs earlier in the server function (at `app.R:568` approximately). If `session$userData$session_id` is NULL (logger called before `init_session_isolation`), the function early-returns a WARN log and writes nothing.
- `lang` — `tryCatch(i18n$get_translation_language(), error = function(e) "en")`.
- `app_version` — `APP_VERSION` constant from `constants.R` (verified at top-level, global scope).

**Serialization**: built via `jsonlite::toJSON(list(ts = ..., event = ...), auto_unbox = TRUE)` then `paste0(..., "\n")`. NOT hand-rolled `sprintf`. This protects against future fields containing quotes, backslashes, or unicode (e.g., if `lang` ever carries a localized description instead of an ISO code).

**`log_session_end(session_id, start_time)`** — Writes a session_end NDJSON line:

```json
{"ts":"2026-04-11T22:58:04Z","event":"session_end","session_id":"sess_abc123...","duration_s":771}
```

Parameters are pre-captured locals passed by the caller (not extracted from `session` at end time) because `session$userData` may be partially torn down by the time `onSessionEnded` fires in some shutdown paths.

`duration_s` — `as.integer(round(as.numeric(difftime(Sys.time(), start_time, units = "secs"))))`.

Start events deliberately omit `duration_s` — consumers join start + end on `session_id` to compute duration retroactively. Documented in the non-goals section of this spec.

### Concurrency

Shiny Server OSS runs each app instance as a **separate R worker process** under `simple_scheduler`. Multiple sessions can write to the same daily log file simultaneously from different processes.

Safety relies on POSIX write-append atomicity, with caveats:

- `cat(line, file = path, append = TRUE)` in R opens the file in append mode (`"a"` → `open(O_APPEND)`), writes, and closes per call.
- On **local Linux filesystems** (ext4, xfs, tmpfs — which laguna uses), `write()` calls under `PIPE_BUF` (4096 bytes on x86_64) with `O_APPEND` are atomic: two processes appending simultaneously produce two intact sequential entries, never an interleaved half-line. This is a Linux kernel guarantee for local FS.
- **Not guaranteed on NFS** or other networked filesystems. Laguna's `/var/log/` is local disk — verified.
- Our lines are ~200 bytes (grew from ~150 when we reverted the session_id truncation) — still well under 4KB.
- In practice, R's `cat()` issues a single `write()` syscall for short strings, so the atomicity guarantee holds. If R's internal buffering ever splits the write, behavior is undefined but still unlikely to corrupt entries given the append mode.

Result: no mutex, no file locking, no per-session file, no log aggregator. Just one daily file written by many processes, safely on local Linux disks.

### Error handling

The contract: **no codepath in the session logger can raise an exception that reaches Shiny's main loop.**

- `resolve_session_log_dir` wraps `dir.create` and `file.access` in `tryCatch`. Any failure → next strategy in the resolution order, with a WARN-level `debug_log` on the first failure (so ops sees it in the daemon log) and DEBUG-level on subsequent cache hits.
- `log_session_start` and `log_session_end` wrap their entire bodies in `tryCatch(..., error = function(e) { debug_log(paste("session_logger failed:", conditionMessage(e)), "SESSION_LOG"); invisible(NULL) })`. Disk full, file permission change mid-session, JSON serialization error, cached path stale — all caught, logged to the existing debug_log stream, ignored.
- Field extraction is individually guarded: `tryCatch(i18n$get_translation_language(), error = function(e) "en")`. The session ID and start time are passed in as already-computed locals by the caller, so the logger itself does not touch `session$...` at write time (protects against `onSessionEnded` timing where session state may be partially torn down).
- `onSessionEnded` callback contents are wrapped by Shiny's own error handler, plus our internal `tryCatch` — double guard.
- If `resolve_session_log_dir` returns `NULL`, both `log_session_*` functions early-return `invisible(NULL)` and do nothing. Logging is effectively off; the app runs normally.

## Data flow

```
Browser connects
    ↓
Shiny server function starts (app.R)
    ↓
init_session_isolation(session)   [EXISTING at app.R:568]
    ├─ sets session$userData$session_id
    └─ registers onSessionEnded for cleanup (existing callback #1)
    ↓
[NEW WIRING — Sprint 5 Task 2]
session_start_time <- Sys.time()
sid <- session$userData$session_id
log_session_start(session, i18n)
session$onSessionEnded(function() log_session_end(sid, session_start_time))
    ↑ second callback, chains with the cleanup one — Shiny supports N callbacks
    ↓
    [1 line appended to sessions-YYYY-MM-DD.jsonl via single cat(append=TRUE)]
    ↓
Session runs (modules init, user interacts, ...)
    ↓
Browser disconnects / session times out / daemon clean restart
    ↓
Shiny runs BOTH onSessionEnded callbacks in registration order:
    1. cleanup_session_isolation(session_id, session_temp_dir)  [existing]
    2. log_session_end(sid, session_start_time)                  [new]
    ↓
    [1 line appended]
```

Callback ordering note: if cleanup throws (unlikely), Shiny continues to the next callback. Our logger still fires.

## Testing strategy

**Unit tests** — `tests/testthat/test-session-logger.R`, 5 cases:

1. **Resolver happy path**: mock `dir.create` and `file.access` to both succeed → `resolve_session_log_dir` returns the canonical path.
2. **Resolver fallback**: mock `file.access` on canonical path to return -1 (failure) but tempdir fallback to succeed → returns tempdir subpath.
3. **Resolver caching**: call `resolve_session_log_dir` twice, verify second call does not re-invoke the underlying file checks (use `mockery::stub` or a call counter).
4. **Start-line round-trip**: call `log_session_start` with a mock session (`session$userData$session_id = "sess_test123"`, `i18n$get_translation_language()` returning `"fr"`), assert the resulting file contains one line, parse with `jsonlite::fromJSON(..., simplifyVector = FALSE)`, check all 5 fields match expected values.
5. **No-throw on unwritable path**: `log_session_start` called when `resolve_session_log_dir` has been forced to return `NULL` (via direct env manipulation, not OS-level readonly — avoids Windows NTFS ACL complications). Wrap in `expect_no_error` and assert no file was written.

**End-line coverage**: implicit in test 4 — the round-trip test calls both `log_session_start` and `log_session_end` to the same file, reads back both lines, asserts end event has `event = "session_end"`, correct `session_id`, and `duration_s >= 0`.

**Integration test**: skipped. Testing actual multi-process appends would require a test harness that spawns multiple R processes, which isn't worth the fixture complexity for a best-effort logger.

**Cross-platform**: all 5 tests use mocks or direct env manipulation, not OS-level permission changes. Runs on Linux CI, macOS, and Windows identically. No `skip_on_os` needed.

**Manual post-deploy verification** (recorded in the plan's Final Verification):

```bash
ssh razinka@laguna.ku.lt "ls /var/log/shiny-server/marinesabres/sessions-*.jsonl 2>/dev/null && tail -5 /var/log/shiny-server/marinesabres/sessions-*.jsonl | jq ."
```

Expect: one daily-named `.jsonl` file, with at least one parseable `session_start` entry matching the verifier's own browser session from immediately after the restart. Pipe through `jq .` to validate JSON.

## Deployment

- **No ops prerequisites**. The shiny user has write permission on `/var/log/shiny-server/` (verified 2026-04-11: `drwxr-xr-x 2 shiny shiny`), so `dir.create(..., recursive = TRUE)` works on first connection. A manual `sudo -u shiny mkdir -p /var/log/shiny-server/marinesabres` has already been run as part of the review process, so the directory exists immediately.
- **No deploy-script changes**. The log file lives in `/var/log/`, outside the app target directory, so `rm -rf $REMOTE_TARGET/*` in `remote-deploy.sh` cannot touch it.
- **No `shiny-server.conf` changes**. This is pure R-side; the Pro-only `session_logging` directive stays out of our config file.
- **Compatible with the existing deploy flow**: `git push`, `bash deployment/remote-deploy.sh --force`, `ssh -t ... sudo systemctl restart shiny-server`, `curl` check. Identical to prior sprints.

## Future extensions (not in this spec)

The NDJSON log file is an append-only event stream — future work can layer on top without schema breakage:

- New event types: `project_saved`, `project_loaded`, `language_changed`, `analysis_started`. Each adds a line with its own `event` tag and relevant fields.
- Admin module that reads today's file, parses with `jsonlite::stream_in`, surfaces basic metrics inside the app.
- Structured log ingestion (Loki, Elastic, Vector) — NDJSON is already a supported input.
- Logrotate policy if daily files accumulate beyond 30-60 days — add `/etc/logrotate.d/shiny-server-marinesabres` config.

Out of scope for this initial spec. YAGNI.
