import json, re, os, glob

base = r"C:\Users\arturas.baziukas\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny"

# Collect ALL translation keys
existing_keys = set()
for jf in glob.glob(os.path.join(base, "translations", "**", "*.json"), recursive=True):
    try:
        with open(jf, encoding="utf-8") as f:
            data = json.load(f)
        for k in data.get("translation", {}).keys():
            existing_keys.add(k)
    except:
        pass

print(f"Total translation keys: {len(existing_keys)}")

# Extract keys from R files
pattern = re.compile(r'i18n\$t\("([^"]+)"\)')
r_files = (
    glob.glob(os.path.join(base, "modules", "*.R"))
    + glob.glob(os.path.join(base, "server", "*.R"))
    + glob.glob(os.path.join(base, "*.R"))
)

all_missing = {}
for rf in r_files:
    with open(rf, encoding="utf-8", errors="ignore") as f:
        content = f.read()
    used_keys = set(pattern.findall(content))
    missing = sorted(used_keys - existing_keys)
    if missing:
        short = os.path.relpath(rf, base)
        all_missing[short] = missing

# Report
total_missing = sum(len(v) for v in all_missing.values())
print(f"Files with missing keys: {len(all_missing)}")
print(f"Total missing keys: {total_missing}")
print()
for f, keys in sorted(all_missing.items()):
    print(f"--- {f} ({len(keys)} missing) ---")
    for k in keys:
        print(f"  {k}")
    print()
