#!/usr/bin/env python
"""One-off i18n audit: find missing, unused, incomplete keys + hardcoded strings.

Supports --allow-english-fallback=<prefix1,prefix2> to suppress English-fallback
warnings for keys whose module name starts with one of the given prefixes.
This is used during phased i18n delivery (see WP5 spec §9.1) where chrome
strings ship with English values in non-EN locales until backfill closes.
"""
import re, os, json, glob, sys, argparse

# ---- Argument parsing ----
_ap = argparse.ArgumentParser(description=__doc__)
_ap.add_argument(
    "--allow-english-fallback",
    type=str,
    default="",
    help="Comma-separated module-name prefixes for which English-fallback values are accepted (e.g. 'wp5'). The audit's English-fallback report omits matching keys.",
)
_args, _unknown = _ap.parse_known_args()
ENGLISH_FALLBACK_PREFIXES = tuple(p.strip() for p in _args.allow_english_fallback.split(",") if p.strip())


def _is_allowlisted_english_fallback(key: str) -> bool:
    """A key is allowlisted if its module name (second dot segment) starts with
    one of the --allow-english-fallback prefixes, e.g. 'modules.wp5_*'."""
    if not ENGLISH_FALLBACK_PREFIXES:
        return False
    parts = key.split(".")
    if len(parts) < 2:
        return False
    module = parts[1]
    return any(module.startswith(p) for p in ENGLISH_FALLBACK_PREFIXES)


root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(root)

# ---- 1. Collect used keys ----
used = {}  # key -> list of (file, line)
# Patterns that reference an i18n key:
#   i18n$t("key")                    - direct translator call
#   safe_t("key", i18n_obj = ...)    - safe wrapper (see functions/error_handling.R
#                                      and usage in functions/ui_sidebar.R et al.)
#   `data-i18n` = "key"              - HTML attribute for client-side lookup
#   `data-i18n-title` = "key"        - variant for tooltip titles
#   context_key = "key"              - format_user_error() argument (i18n-translated
#                                      at call time; added when the `context` param
#                                      was migrated away from raw English strings)
#   # i18n-ref: key.name             - explicit sentinel for dynamically-constructed
#                                      lookups (e.g., paste0(prefix, dynamic_code)
#                                      where the key can't be matched statically)
# Missing ANY of these patterns causes the audit to wrongly flag the key as
# unused — a bug that cost a KB-regression commit/revert cycle earlier.
patterns = [
    re.compile(r'i18n\$t\(\s*["\']([^"\']+)["\']'),
    re.compile(r'safe_t\(\s*["\']([^"\']+)["\']'),
    re.compile(r'`?data-i18n(?:-\w+)?`?\s*=\s*["\']([^"\']+)["\']'),
    re.compile(r'context_key\s*=\s*["\']([^"\']+)["\']'),
]
# Sentinel pattern is applied BEFORE comment-skipping — it ONLY matches comments
# by design, so must run on the raw line or the lstrip-startswith('#') guard below
# would silently drop every sentinel.
sentinel_pattern = re.compile(r'#\s*i18n-ref:\s*([a-zA-Z_][a-zA-Z0-9_.]*)')
targets = []
for base in ['modules', 'server', 'functions']:
    targets.extend(glob.glob(f'{base}/**/*.R', recursive=True))
for f in ['app.R', 'global.R']:
    if os.path.isfile(f):
        targets.append(f)

for f in targets:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            for i, line in enumerate(fh, 1):
                # Sentinel runs on ALL lines (including comment-only) because
                # the pattern only matches inside a comment by design.
                for m in sentinel_pattern.finditer(line):
                    used.setdefault(m.group(1), []).append((f, i))
                # Strip R comments for the remaining patterns (naive — does not
                # respect strings, but R strings rarely contain '#' before i18n)
                if line.lstrip().startswith('#'):
                    continue
                for pat in patterns:
                    for m in pat.finditer(line):
                        used.setdefault(m.group(1), []).append((f, i))
    except Exception as e:
        pass

# ---- 1b. Also scan validate_translation_completeness critical keys ----
# These keys are not referenced via i18n$t() directly but through a runtime
# validation function that checks if each key resolves. The keys appear in a
# hardcoded vector in global.R. Pattern match the block between
# `critical_keys <- c(` and the closing `)`.
critical_key_pat = re.compile(r'critical_keys\s*<-\s*c\(([^)]*)\)', re.DOTALL)
quoted_key_pat = re.compile(r'"([a-zA-Z_][a-zA-Z0-9_.]*)"')
if os.path.isfile('global.R'):
    try:
        with open('global.R', 'r', encoding='utf-8') as fh:
            content = fh.read()
        for m in critical_key_pat.finditer(content):
            block = m.group(1)
            # Find which line the block starts on for reporting
            start_line = content[:m.start()].count('\n') + 1
            for km in quoted_key_pat.finditer(block):
                key = km.group(1)
                # Compute absolute line number within the file
                key_offset = m.start() + km.start()
                key_line = content[:key_offset].count('\n') + 1
                used.setdefault(key, []).append(('global.R', key_line))
    except Exception as e:
        pass

# ---- 2. Collect defined keys ----
# Format: { "translation": { "some.key.name": { "en": "...", "es": "..." } } }
defined = {}  # key -> { lang -> value }
key_source = {}  # key -> file

tfiles = [f for f in glob.glob('translations/**/*.json', recursive=True)
          if '_merged' not in f]
for tf in tfiles:
    try:
        with open(tf, 'r', encoding='utf-8') as fh:
            data = json.load(fh)
        tr = data.get('translation', {})
        if isinstance(tr, dict):
            for key, langs in tr.items():
                if isinstance(langs, dict):
                    defined.setdefault(key, {}).update(langs)
                    key_source.setdefault(key, tf)
    except Exception as e:
        print(f'ERR loading {tf}: {e}', file=sys.stderr)

REQ = {'en', 'es', 'fr', 'de', 'lt', 'pt', 'it', 'no', 'el'}

# ---- 3. Missing keys ----
# The i18n engine uses hierarchical keys; the dot paths in JSON are reconstructed.
# Some code uses flat keys and some nested. Consider a key "found" if it exists at
# any level (exact match).
missing = sorted([k for k in used if k not in defined and k != 'modules.isa.ai_assistant.youve_approved'])

# ---- 4. Unused keys ----
used_set = set(used.keys())
unused = sorted([k for k in defined if k not in used_set])

# ---- 5. Incomplete ----
incomplete = []
for k, langs in defined.items():
    miss = REQ - set(langs.keys())
    if miss:
        incomplete.append((k, sorted(miss)))
incomplete.sort()

# ---- 5b. English-fallback (key has all locales but non-EN values equal EN) ----
# Used during phased i18n delivery (see WP5 spec §9.1). Reported separately
# from "incomplete" because all locales ARE present — they just carry the EN
# string verbatim. The --allow-english-fallback CLI flag suppresses matching
# module prefixes from this report (allowing partial-translation milestones
# to ship without spurious audit noise).
english_fallback = []
for k, langs in defined.items():
    en_val = langs.get('en')
    if not en_val:
        continue
    fallback_locales = sorted([
        loc for loc in REQ
        if loc != 'en' and loc in langs and langs[loc] == en_val
    ])
    if fallback_locales:
        english_fallback.append((k, fallback_locales))
english_fallback.sort()
# Apply --allow-english-fallback allowlist
english_fallback_reported = [
    (k, locs) for (k, locs) in english_fallback
    if not _is_allowlisted_english_fallback(k)
]

# ---- 6. Hardcoded strings ----
# Scan modules/ for suspicious patterns
hardcoded = []
patterns = [
    (re.compile(r'showNotification\(\s*"([^"]{3,})"'), 'showNotification'),
    (re.compile(r'actionButton\([^,]+,\s*"([A-Z][^"]{2,})"'), 'actionButton'),
    (re.compile(r'\btags\$span\(\s*"([A-Z][^"]{3,})"'), 'tags$span'),
    (re.compile(r'\bh[1-6]\(\s*"([A-Z][^"]{3,})"'), 'h_'),
    (re.compile(r'\bp\(\s*"([A-Z][^"]{5,})"'), 'p()'),
    (re.compile(r'title\s*=\s*"([A-Z][^"]{3,})"'), 'title='),
    (re.compile(r'label\s*=\s*"([A-Z][^"]{3,})"'), 'label='),
    (re.compile(r'placeholder\s*=\s*"([A-Z][^"]{3,})"'), 'placeholder='),
]
# Only scan a few recently-touched files per the recent commits
for f in glob.glob('modules/**/*.R', recursive=True):
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except Exception:
        continue
    for i, line in enumerate(lines, 1):
        # skip if line already uses i18n$t on that call, or comment
        stripped = line.lstrip()
        if stripped.startswith('#'):
            continue
        for pr, tag in patterns:
            for m in pr.finditer(line):
                val = m.group(1)
                # Only flag if i18n$t not used on same line for this call
                if 'i18n$t' in line:
                    continue
                # Skip obvious non-English
                if val.lower() in ('true', 'false', 'null', 'na'):
                    continue
                # Skip CSS / html-ish
                if any(c in val for c in ['<', '>', '/', '{', '}', ':', ';']):
                    continue
                # Must contain a space or look like English (avoid IDs)
                if ' ' not in val and not re.search(r'[a-z][A-Z]', val):
                    if len(val.split()) == 1 and val.islower():
                        continue
                hardcoded.append((f, i, tag, val))
                break

# ---- Emit report ----
out = []
out.append('# i18n Audit Report\n')
out.append(f'_Generated {os.popen("date /t" if os.name=="nt" else "date").read().strip()}_\n')
out.append(f'\nTotals: used={len(used)}  defined={len(defined)}  missing={len(missing)}  unused={len(unused)}  incomplete={len(incomplete)}  english_fallback={len(english_fallback_reported)}  hardcoded={len(hardcoded)}\n')

out.append('\n## Missing Keys (MUST FIX)\n')
for k in missing[:30]:
    f, ln = used[k][0]
    out.append(f'- `{k}` — referenced at `{f}:{ln}` — FIX: add to appropriate `translations/**/*.json`')
if len(missing) > 30:
    out.append(f'- ... and {len(missing)-30} more')

out.append('\n## Incomplete Translations (IMPORTANT)\n')
for k, miss in incomplete[:30]:
    out.append(f'- `{k}` — missing languages: {", ".join(miss)}')
if len(incomplete) > 30:
    out.append(f'- ... and {len(incomplete)-30} more')

out.append('\n## English-Fallback Translations (INFO)\n')
if ENGLISH_FALLBACK_PREFIXES:
    n_suppressed = len(english_fallback) - len(english_fallback_reported)
    out.append(
        f'_Allowlisted module prefixes: {", ".join(ENGLISH_FALLBACK_PREFIXES)} — {n_suppressed} key(s) suppressed from this report._\n'
    )
out.append(
    'Keys present in all 9 locales but where one or more non-EN values match the EN value verbatim. Expected during phased i18n delivery; track in the relevant backfill ticket.\n'
)
for k, locs in english_fallback_reported[:30]:
    out.append(f'- `{k}` — non-EN locales using EN fallback: {", ".join(locs)}')
if len(english_fallback_reported) > 30:
    out.append(f'- ... and {len(english_fallback_reported)-30} more')

out.append('\n## Hardcoded Strings (IMPORTANT)\n')
for f, ln, tag, val in hardcoded[:30]:
    val_show = val.replace('|', '\\|')
    out.append(f'- `{f}:{ln}` [{tag}] — "{val_show}" should be `i18n$t("...")`')
if len(hardcoded) > 30:
    out.append(f'- ... and {len(hardcoded)-30} more')

out.append('\n## Unused Keys (MINOR)\n')
for k in unused[:30]:
    src = key_source.get(k, '?')
    out.append(f'- `{k}` — defined in `{src}` but not referenced')
if len(unused) > 30:
    out.append(f'- ... and {len(unused)-30} more')

report = '\n'.join(out)
os.makedirs('.claude/skills/scientific-validation-workspace/codebase-audit', exist_ok=True)
report_path = '.claude/skills/scientific-validation-workspace/codebase-audit/i18n-audit-report.md'
with open(report_path, 'w', encoding='utf-8') as fh:
    fh.write(report)

print(report)
print(f'\n[written to {report_path}]')
