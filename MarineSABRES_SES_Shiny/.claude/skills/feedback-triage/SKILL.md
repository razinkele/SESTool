---
name: feedback-triage
description: Pull live user feedback from laguna, triage it, drive a checkpointed fix cycle per entry, and mark each entry addressed in the live log. Use when the user asks to triage/work the feedback backlog, check user-reported bugs/suggestions, or "address the feedback".
---

# Feedback Triage

Work the live MarineSABRES user-feedback backlog end to end. Irreversible/destructive
actions (the FIRST live-log write of a session, every merge, GitHub-issue close, and
deploy) are ALWAYS user-gated — ask and wait, never proceed unprompted.

## 0. Constants
- Live log: `LOG=/srv/shiny-server/marinesabres/data/user_feedback_log.ndjson` on `razinka@laguna.ku.lt`.
- Lockfile: `$LOG.lock`. Run ALL ssh from the Bash tool (PowerShell ssh hangs on stdin here).
- Repo root one level up at the SESToolbox dir; app subdir `MarineSABRES_SES_Shiny/`.

## 1. Pull + back up (verified, per-invocation)
- `STAMP=$(date +%F-%H%M%S)-$$`
- `ssh -n razinka@laguna.ku.lt "cp $LOG /tmp/feedback_backup_$STAMP.ndjson && wc -l $LOG /tmp/feedback_backup_$STAMP.ndjson"` — confirm the two line counts MATCH; if the backup step fails, STOP.
- `ssh -n razinka@laguna.ku.lt "cat $LOG" > local_feedback.ndjson` — record `N = wc -l` (the line count you triage against; passed later as `expect_total_lines`).

## 2. Triage
- Parse each line; no `status` = OPEN; `duplicate_of` (≠ "NA"/"") ⇒ duplicate.
- Reconcile: if (parsed entries) < (raw non-blank lines), some lines are malformed — list them as "needs manual triage", do not silently skip.
- Keep OPEN `bug`/`suggestion`; detect duplicates by similar title; prioritize bugs.
- Present a numbered list: line · type · title · one-line assessment. Large backlog → one read-only Agent per entry to classify, then proceed sequentially.

## 3. Per entry (checkpointed)
For each OPEN bug, in priority order:
1. Reproduce + diagnose — invoke `superpowers:systematic-debugging`.
2. Fix — invoke `superpowers:test-driven-development` (failing test → fix → green).
3. Branch + commit + PR (`git -C "<SESToolbox root>"`, prefix paths with `MarineSABRES_SES_Shiny/`).
4. **Ask the user to approve the merge.** Never merge unprompted.
5. On merge → mark addressed (NEVER interpolate the note/title into a command; pass via a params file):
   a. Write `params.json` LOCALLY: `{"log":"$LOG","match_title":"<exact title>","match_timestamp":"<exact timestamp>","status":"addressed","resolved_by":"feedback-triage","note":"<note>","fix_ref":"<PR/SHA>","expect_total_lines":N}` (encode with a JSON library / jq — do not hand-concatenate).
   b. `scp params.json mark_resolved_remote.R razinka@laguna.ku.lt:/tmp/ && ssh -n razinka@laguna.ku.lt "flock $LOG.lock Rscript /tmp/mark_resolved_remote.R /tmp/params.json"` — chain with `&&`; CHECK THE ssh EXIT CODE (0 = success). Non-zero = STOP, report "mark FAILED" (do NOT record the entry as resolved).
   c. Confirm: `ssh -n razinka@laguna.ku.lt "grep -F '<exact title>' $LOG"` and verify the line now has `"status":"addressed"`. If confirmation fails, report FAILED — never report addressed on an unverified write.
   - If the marker prints `file grew` (a user submitted during triage), STOP, re-pull (1), recompute `N`, retry — prevents losing the user's new entry.
For suggestions: assess; implement if small (same flow) else write a concrete proposal and ask before implementing.
For duplicate / won't-fix / already-works: same params-file marker with that `status` + a note (no code change).
If the entry has a `github_url` AND `MARINESABRES_GITHUB_TOKEN` is set: ask before `gh issue close` with a resolution comment. If the token is absent, SKIP (never prompt for/echo a token).

## 4. Deploy gate
After a batch of fixes is merged, surface the user-gated `git archive` deploy
(`deployment/deploy-remote.ps1`, run via Bash with `< /dev/null`). After a verified
deploy, re-run the params-file marker for each resolved entry with the SAME
match_title/match_timestamp/status/fix_ref PLUS `"fix_deployed":"<laguna Version>"`
(re-pull + fresh `expect_total_lines` first).

## 5. Report
Triaged N · fixed M (PR refs + statuses) · pending-deploy · malformed/needs-manual · deferred.

## Safety
- Never mark `addressed` before the fix is merged; treat the first live-log write as a gated checkpoint.
- Skip entries already `addressed`/`duplicate`.
- The marker matches by (title,timestamp) and aborts if the file grew — a concurrent user submission makes a mark FAIL (re-pull), never lose data.
- Pass all free text via the params file — NEVER interpolate user/feedback text into an ssh command string.
- Triage-only mode: do 2 and stop (no marking, no code).
