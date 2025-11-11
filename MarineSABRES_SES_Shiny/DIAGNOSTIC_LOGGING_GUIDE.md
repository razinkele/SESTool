# Loop Detection Diagnostic Logging Guide

## Overview

Comprehensive diagnostic logging has been added to the loop detection feature to help identify exactly where delays or hangs occur.

## How to Use

1. **Start the app** normally
2. **Load your ISA project**
3. **Go to Analysis Tools → Loop Detection**
4. **Open the R console** (where the app is running)
5. **Click "Detect Loops"**
6. **Watch the console output** in real-time

## What You'll See

### Example Output (Successful Detection):

```
═══════════════════════════════════════════════════════════════════
[LOOP DETECTION] Button clicked at 14:35:22
═══════════════════════════════════════════════════════════════════
[STEP 1/7] Building graph from ISA data...
[STEP 1/7] ✓ Graph built in 0.045 seconds
[GRAPH INFO] Nodes: 28, Edges: 52
[GRAPH INFO] Density: 0.0686
[STEP 2/7] Analyzing strongly connected components...
[STEP 2/7] ✓ SCC analysis completed in 0.012 seconds
[SCC INFO] Number of components: 12
[SCC INFO] Largest component: 8 nodes
[SCC INFO] Average component size: 2.3 nodes
[STEP 3/7] Preparing detection parameters...
[STEP 3/7] ✓ Parameters set: max_length=8 (requested: 10), max_cycles=500
[STEP 4/7] Starting cycle detection...
[TIMING] Detection start: 14:35:22.156
[TIMEOUT] Set to 30 seconds
[TIMEOUT] Reset
[STEP 4/7] ✓ Cycle detection completed in 0.234 seconds
[RESULT] Found 15 cycles
[STEP 5/7] Limiting loops for display...
[STEP 5/7] ✓ Will process 15 loops
[STEP 6/7] Processing cycles to dataframe...
[STEP 6/7] ✓ Processing completed in 0.067 seconds
[RESULT] Created dataframe with 15 rows
[STEP 7/7] Saving results...
[STEP 7/7] ✓ Results saved in 0.023 seconds
═══════════════════════════════════════════════════════════════════
[LOOP DETECTION] Completed successfully at 14:35:22
[SUMMARY] Total loops found: 15
═══════════════════════════════════════════════════════════════════
```

---

## Interpreting the Output

### Step-by-Step Breakdown

| Step | What It Does | Expected Time | What to Watch For |
|------|-------------|---------------|-------------------|
| **STEP 1** | Builds igraph from ISA data | <0.1s | Should be instant |
| **STEP 2** | Analyzes strongly connected components | <0.05s | Check SCC sizes |
| **STEP 3** | Sets detection parameters | <0.01s | Confirms max_length cap |
| **STEP 4** | **Runs cycle detection** | **<3s typical** | **Most time spent here** |
| **STEP 5** | Limits results for display | <0.01s | Shows if limiting occurred |
| **STEP 6** | Converts cycles to dataframe | <0.2s | Can be slow with many loops |
| **STEP 7** | Saves to project data | <0.05s | Should be instant |

### Key Metrics to Check

#### 1. **Network Size**
```
[GRAPH INFO] Nodes: 28, Edges: 52
[GRAPH INFO] Density: 0.0686
```

**What's Normal:**
- Nodes: 10-50 (small), 50-100 (medium), 100-200 (large)
- Density: <0.10 (sparse), 0.10-0.30 (moderate), >0.30 (dense)

**Red Flags:**
- ❌ Density > 0.15 with >40 nodes → May cause slowdown
- ❌ Nodes > 100 → May take longer

---

#### 2. **SCC Structure**
```
[SCC INFO] Number of components: 12
[SCC INFO] Largest component: 8 nodes
[SCC INFO] Average component size: 2.3 nodes
```

**What's Good:**
- ✅ Many small components (5-20 components)
- ✅ Largest component <20 nodes
- ✅ Average size <5 nodes

**Red Flags:**
- ❌ Single component with >35 nodes
- ❌ Largest component >50 nodes
- ❌ Few large components instead of many small

---

#### 3. **Detection Time (STEP 4)**
```
[STEP 4/7] ✓ Cycle detection completed in 0.234 seconds
[RESULT] Found 15 cycles
```

**What's Normal:**
- ✅ <1 second: Excellent
- ✅ 1-3 seconds: Good
- ⚠️ 3-10 seconds: Acceptable for large networks
- ⚠️ 10-30 seconds: Slow but within timeout
- ❌ No output for >30 seconds: **HANGING** (shouldn't happen)

**If STEP 4 is slow (>5 seconds):**
- Check SCC structure (above)
- Check network density
- Large dense component likely present

---

#### 4. **Processing Time (STEP 6)**
```
[STEP 6/7] ✓ Processing completed in 0.067 seconds
```

**What's Normal:**
- ✅ <0.1s for <50 loops
- ✅ <0.5s for 50-200 loops
- ⚠️ <2s for 200-500 loops

**If STEP 6 is slow (>2 seconds):**
- Many loops detected (check STEP 5 output)
- Should still complete, just takes time

---

## Diagnosing Issues

### Scenario 1: Output Stops at STEP 4 (No completion message)

```
[STEP 4/7] Starting cycle detection...
[TIMING] Detection start: 14:35:22.156
[TIMEOUT] Set to 30 seconds
(no further output for >30 seconds)
```

**Diagnosis:** Cycle detection is hanging despite optimizations

**Possible Causes:**
1. **Large dense SCC not caught by filters**
   - Check STEP 2 output for SCC sizes
   - If largest SCC >35 nodes with >6% density → filter may not catch it

2. **Specific network structure**
   - Your data has an edge case
   - Export network structure for analysis

**What To Do:**
1. Check console at the moment it stops
2. Note the SCC INFO from STEP 2
3. Report to developer with:
   - Network size (STEP 1 output)
   - SCC structure (STEP 2 output)
   - Where it stopped

---

### Scenario 2: Gets Timeout Error

```
[STEP 4/7] ✗ ERROR after 30.001 seconds: reached elapsed time limit
[ERROR] Timeout occurred
```

**Diagnosis:** Detection took longer than 30 seconds

**Possible Causes:**
- Network structure causes slow detection
- Density threshold may need adjustment

**What To Do:**
1. Check SCC INFO - likely has large dense component
2. Try network simplification first:
   - Analysis Tools → Simplification → Endogenization
   - Analysis Tools → Simplification → Encapsulation
3. Reduce max_cycles or max_loop_length settings

---

### Scenario 3: STEP 4 Completes But No Cycles Found

```
[STEP 4/7] ✓ Cycle detection completed in 0.156 seconds
[RESULT] Found 0 cycles
[INFO] No loops found in network
```

**Diagnosis:** Network has no cycles (normal for some structures)

**Possible Reasons:**
- Tree structure (no feedback loops)
- All cycles longer than max_length (8)
- Components were skipped (check for warnings)

**What To Do:**
1. Check if you completed ISA Exercise 6 (loop closure connections)
2. Increase max_loop_length if you have long chains
3. Check for "Skipping large dense component" warnings

---

### Scenario 4: Completes Quickly But UI Still Frozen

```
═══════════════════════════════════════════════════════════════════
[LOOP DETECTION] Completed successfully at 14:35:23
[SUMMARY] Total loops found: 45
═══════════════════════════════════════════════════════════════════
(console shows completion, but browser UI still appears frozen)
```

**Diagnosis:** Code worked, but UI rendering is slow

**Possible Causes:**
- DataTable rendering many loops
- Browser performance issue
- Reactive chain triggered expensive re-render

**What To Do:**
1. Wait 5-10 more seconds - rendering may catch up
2. Check browser console (F12) for JavaScript errors
3. Try with fewer loops (reduce max_cycles setting)

---

## Performance Expectations

### By Network Size

| Nodes | Edges | Typical Time | Max Time |
|-------|-------|-------------|----------|
| 10-20 | <40 | <0.5s | 1s |
| 20-40 | 40-80 | <1s | 3s |
| 40-80 | 80-150 | 1-3s | 10s |
| 80-150 | 150-300 | 3-10s | 30s |
| >150 | >300 | May timeout | 30s (limit) |

### Warning Signs

| Indicator | Value | Concern Level |
|-----------|-------|---------------|
| Largest SCC | >50 nodes | 🔴 HIGH |
| Largest SCC | 35-50 nodes | 🟡 MEDIUM |
| Density | >0.15 | 🟡 MEDIUM |
| Density + Large SCC | >0.08 with >40 nodes | 🔴 HIGH |
| Step 4 time | >10 seconds | 🟡 MONITOR |
| Step 4 time | >25 seconds | 🔴 NEAR TIMEOUT |

---

## Quick Troubleshooting

### "It's Been 15 Seconds and Nothing Happened"

1. **Check console** - Is it printing progress?
   - **YES** → It's working, be patient
   - **NO** → Button click may not have registered, try again

2. **Look for STEP 4 message**
   - **Printed** → It's in cycle detection, wait for result
   - **Not printed** → Earlier step failed, check for errors

3. **Check SCC INFO**
   - **Many small components** → Should be fast
   - **One large component (>40 nodes)** → May take time or be skipped

### "I See STEP 4 Start But No Completion"

1. **Wait full 30 seconds** for timeout
2. **Check if timeout error appears**
   - **YES** → Network too complex, use simplification
   - **NO** → True hang (report this!)

3. **Note the time** - How long did you wait?
   - **<30s** → Still within timeout, be patient
   - **>30s** → Timeout mechanism may have failed

### "Everything Completed in Console But UI Frozen"

1. **Wait 10 more seconds** - UI may be rendering
2. **Check browser tab title** - Does it say "(Not Responding)"?
   - **YES** → Browser issue, wait or refresh
   - **NO** → Check for JavaScript errors in browser console

3. **Try refreshing browser** - Does the data persist?
   - **YES** → Auto-save worked, just UI issue
   - **NO** → Data lost, but rare

---

## Reporting Issues

If you experience hanging despite this logging, please provide:

### Required Information:

1. **Complete console output** from the diagnostic logging
2. **Network characteristics:**
   ```
   [GRAPH INFO] Nodes: ?, Edges: ?
   [GRAPH INFO] Density: ?
   [SCC INFO] Number of components: ?
   [SCC INFO] Largest component: ? nodes
   ```
3. **Where it stopped:** Which STEP was the last one printed?
4. **How long it hung:** Actual elapsed time
5. **Any warnings or errors** shown

### Example Report:

```
ISSUE: Loop detection hangs at STEP 4

Network Info:
- Nodes: 42
- Edges: 135
- Density: 0.0785
- Largest SCC: 38 nodes
- Number of SCCs: 5

Console Output:
[STEP 4/7] Starting cycle detection...
[TIMING] Detection start: 14:35:22.156
[TIMEOUT] Set to 30 seconds
(no further output after 35 seconds)

Expected: Should skip large component or complete within 30s
Actual: No output, no timeout error
```

---

## Next Steps

With this logging in place, you should be able to:
1. ✅ See exactly where any delays occur
2. ✅ Identify problematic network structures
3. ✅ Distinguish between code hangs and UI responsiveness
4. ✅ Provide detailed bug reports if needed

**Try it now:**
1. Restart your app (to load the new logging code)
2. Load your ISA project
3. Run loop detection
4. Watch the console output
5. Share what you see!

---

**Diagnostic Logging Added:** 2025-11-10
**Version:** 1.4.0-beta
**Status:** Ready for testing
