# Learning Rate Schedule Analysis: Why 10K Works but 20K Fails

## TL;DR
**The model MUST have LR decay from 1e-4 → 1e-8 within 10K steps to work. Slower decay = 0% success.**

## Root Cause Discovery

| Checkpoint | Steps | Epochs | LR | Loss | Success Rate |
|------------|-------|--------|-----|------|--------------|
| ✅ Standalone 10K @ 10K | 10,000 | 32 | 8.98e-09 | 0.0054 | 12-24% |
| ❌ 20K run @ 10K | 10,000 | 32 | 5.24e-05 | 0.0091 | 0% |
| ❌ 20K run @ 20K | 20,000 | 64 | 2.13e-09 | 0.0026 | 0% |

**Key insight**: At the same epoch count (32), the 20K run fails because LR is 5,839x too high!

## LR Schedule Comparison

### ✅ Successful 10K Run
```
Step     0: LR = 1.01e-05  (warmup start)
Step   500: LR = 9.01e-05  (warmup end)
Step  1000: LR = 9.94e-05  (peak, start decay)
Step  5000: LR = 5.49e-05  (already halved!)
Step  7000: LR = 2.33e-05
Step  9000: LR = 2.98e-06
Step 10000: LR = 8.98e-09  ← CONVERGED ✓
```
**Fast cosine decay over 10K steps** → Model converges properly → 12-24% success

### ❌ Failed 20K Run
```
Step     0: LR = 1.01e-05  (warmup start)
Step   500: LR = 9.01e-05  (warmup end)
Step  1000: LR = 9.99e-05  (peak, start decay)
Step  5000: LR = 8.77e-05  (barely decayed!)
Step  7000: LR = 7.53e-05
Step  9000: LR = 6.04e-05
Step 10000: LR = 5.24e-05  ← STILL HIGH! (5,839x too high)
Step 15000: LR = 1.57e-05
Step 20000: LR = 2.13e-09  ← Finally converged, but TOO LATE
```
**Slow cosine decay over 20K steps** → Undertrained @ 10K, unknown issue @ 20K → 0% success

## Why This Happens

1. **@ 10K steps (32 epochs)**:
   - 10K run: LR ~1e-8, fully converged → Policy works
   - 20K run: LR ~5e-5, halfway through decay → Policy undertrained → 0%

2. **@ 20K steps (64 epochs)**:
   - 20K run: LR ~2e-9, fully converged → But still 0%
   - Hypothesis: Either (a) wrong learning dynamics during slow decay, or (b) 64 epochs causes overfitting even with proper final convergence

## The Solution: Two-Stage Training

**Goal**: Get the fast decay dynamics of 10K run + fine-tuning benefits of 20K run

```
Stage 1 (0-10K):   Train with 10K-step LR schedule
                   LR: 1e-4 → 1e-8 (fast decay)
                   → Saves checkpoint @ 10K (working model)

Stage 2 (10K-20K): Resume from 10K, train with constant LR=1e-8
                   → Fine-tune for another 10K steps
                   → Saves checkpoints @ 12K, 14K, 16K, 18K, 20K
```

**Expected results**:
- 10K checkpoint: 12-24% (matches successful run) ✓
- 12K-20K checkpoints: ≥12-24% (fine-tuning should maintain or improve performance)
- Very low LR (1e-8) prevents overfitting during stage 2

## Training Command

```bash
cd /home/sra/packsarm
source sarm-env/bin/activate
./aloha/scripts/train_dp_aloha_rabc_20k_proper.sh
```

This will:
1. Train 0-10K with fast LR decay (→ working 10K checkpoint)
2. Resume from 10K, fine-tune 10K-20K at LR=1e-8
3. Save checkpoints: 10K, 12K, 14K, 16K, 18K, 20K

## Why Previous Attempts Failed

| Attempt | Issue | Result |
|---------|-------|--------|
| 50K steps (160 epochs) | Severe overfitting | 0% |
| 80K steps w/ 80K LR schedule | All checkpoints undertrained or overtrained | 0% |
| 20K steps w/ 20K LR schedule | Undertrained @ 10K, possible overfit @ 20K | 0% |
| **10K steps w/ 10K LR schedule** | ✅ **Proper convergence** | **12-24%** |

## Verification Metrics

After training, check:
- ✅ 10K checkpoint: LR ~1e-8, loss ~0.005, eval 12-24%
- ✅ 12K-20K: LR stays ~1e-8, loss stays ~0.005 (no overfitting)
- ✅ Eval performance: stable or improving from 10K→20K
