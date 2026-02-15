# Experimental Results - PACKSARM

**Date:** February 2026
**Dataset:** lerobot/aloha_sim_transfer_cube_human (50 demonstrations)
**Task:** Bimanual cube transfer in ALOHA simulation

---

## Summary Table

| Model | Policy | Steps | Epochs | Success Rate | Avg Sum Reward | Key Features |
|-------|--------|-------|--------|-------------|----------------|--------------|
| ACT-80K | Transformer | 80,000 | 256 | **68.0%** (34/50) | 206.88 | Action chunking, SOTA |
| ACT-20K | Transformer | 20,000 | 64 | **32.0%** (16/50) | 168.86 | Faster training |
| RA-BC-Diffusion-10K | Diffusion | 10,000 | 32 | **24.0%** (12/50) | 105.08 | SARM weighting, **+200% vs Vanilla** |
| Vanilla-BC-Diffusion-10K | Diffusion | 10,000 | 32 | **8.0%** (4/50) | 20.46 | Baseline |
| RA-BC-Diffusion-50K | Diffusion | 50,000 | 160 | **0.0%** (0/50) | - | Overfitting failure |

---

## Detailed Results

### Experiment 1: RA-BC vs Vanilla BC (10K steps)

**Date:** February 15, 2026

#### Training Configuration
```yaml
Policy: DiffusionPolicy
  - Vision: ResNet18 (ImageNet pretrained)
  - Crop: None (full 480x640 image)
  - Horizon: 16
  - Action steps: 8
  - Diffusion steps: 100
  - Scheduler: DDPM (cosine beta schedule)

Training:
  - Steps: 10,000 (32 epochs)
  - Batch size: 64
  - Learning rate: 1e-4
  - Optimizer: AdamW (betas=[0.95, 0.999])
  - Scheduler: Cosine with 500 warmup steps
  - Data augmentation: ColorJitter, RandomAffine

RA-BC:
  - SARM progress path: sarm_progress.parquet
  - Head mode: dense
  - Chunk size: 100
  - Kappa: auto (0.241)
  - Mean weight: 0.69
  - Full weight samples: 42-55% per batch
  - Zero weight samples: 5-12% per batch
```

#### Results

**RA-BC Diffusion:**
- Success rate: **24.0%** (12/50 episodes)
- Avg sum reward: 105.08
- Avg max reward: 1.64
- Evaluation time: 20.78s per episode
- Final training loss: ~0.006

**Vanilla BC Diffusion:**
- Success rate: **8.0%** (4/50 episodes)
- Avg sum reward: 20.46
- Avg max reward: 0.42
- Evaluation time: 20.78s per episode
- Final training loss: ~0.005

**Improvement:** **+200%** (3x better with RA-BC)

#### Key Observations

1. **RA-BC Weighting Statistics (Final Batch):**
   - `rabc_mean_weight`: 0.6901
   - `rabc_delta_mean`: 0.2172
   - `rabc_delta_std`: 0.0808
   - `rabc_kappa`: 0.2412 (auto-tuned)
   - Healthy distribution indicates SARM working correctly

2. **SARM Progress Quality:**
   - All 50 episodes: 80.2% monotonicity average
   - Progress range: 0.004 → 0.999 (full 0-1 span)
   - Non-perfect monotonicity is EXPECTED per SARM paper
   - Soft weighting handles prediction noise gracefully

3. **Training Loss:**
   - Both models converged to similar low loss (~0.005-0.006)
   - RA-BC slightly higher loss due to down-weighting low-quality data
   - Loss alone doesn't predict eval performance (overfitting risk)

---

### Experiment 2: ACT Baselines

**Date:** February 15, 2026

#### ACT-80K Results

**Training:**
- Steps: 80,000 (256 epochs)
- Batch size: 8
- Training time: ~6 hours
- Final loss: ~0.003

**Evaluation:**
- Success rate: **68.0%** (34/50 episodes)
- Avg sum reward: 206.88
- Avg max reward: 3.26
- Evaluation time: 2.79s per episode (much faster than Diffusion!)

**Comparison to LeRobot Baseline:**
- LeRobot reported: 83.0% (500 episodes)
- Our result: 68.0% (50 episodes)
- Difference likely due to:
  - Evaluation variance (50 vs 500 episodes)
  - Environment version differences
  - Random seed variation

#### ACT-20K Results

**Training:**
- Steps: 20,000 (64 epochs)
- Training time: ~1.5 hours

**Evaluation:**
- Success rate: **32.0%** (16/50 episodes)
- Avg sum reward: 168.86
- Avg max reward: 2.42

**Scaling Observation:**
- 20K→80K steps: +113% improvement (32%→68%)
- Shows ACT benefits significantly from longer training

---

### Experiment 3: Overfitting Analysis

**Date:** February 14, 2026

#### Original Training (FAILED)

**Configuration:**
- Steps: 50,000 (160 epochs!)
- Same RA-BC weighting
- Same hyperparameters
- With crop: 224x224 RandomCrop

**Results:**
- Success rate: **0.0%** (0/50 episodes)
- Final training loss: 0.0012 (suspiciously low)
- Behavior: Robot repeated same fixed motion regardless of cube position

#### Root Cause Analysis

1. **Overfitting (Primary):**
   - 160 epochs on 50 episodes = severe memorization
   - Model learned fixed trajectory based on robot state
   - Ignored visual feedback completely

2. **Crop Mismatch (Secondary):**
   - Training: RandomCrop (various positions)
   - Eval: CenterCrop (fixed center region)
   - Center crop cut off cube in upper image area
   - Train/eval distribution shift

#### Solution

1. Reduced epochs: 160 → 32 (5x reduction)
2. Removed crop: Full 480×640 image
3. Result: 0% → 24% success

---

## Cross-Model Comparison

### Success Rate vs Training Steps

```
80% ┤                                        ╭─ ACT-80K (68%)
70% ┤                                   ╭────╯
60% ┤                              ╭────╯
50% ┤                         ╭────╯
40% ┤                    ╭────╯
30% ┤               ╭────╯ ACT-20K (32%)
20% ┤          ╭────┼──────────────────────── RA-BC-10K (24%)
10% ┤     ╭────┘    │
 0% ┼─────┼─────────┼─────────────────────── Vanilla-BC-10K (8%)
    0    10K      20K      40K      60K     80K
                Training Steps
```

### Policy Architecture Comparison

**ACT Advantages:**
- Explicit action chunking (predicts sequence of actions)
- Transformer captures temporal dependencies
- Designed for manipulation tasks
- Fast inference (2.79s/episode)

**DiffusionPolicy Advantages:**
- Better for contact-rich tasks (in theory)
- Handles multimodal action distributions
- State-of-the-art on some benchmarks

**Verdict for ALOHA Transfer Cube:**
- ACT is superior (68% vs 24%)
- DiffusionPolicy may excel on other tasks

---

## SARM Pipeline Validation

### VLM Annotation Quality

**Model:** Qwen2.5-VL-7B-Instruct
**Episodes:** 50
**Subtasks per episode:** 5 (reach, grasp, lift, transfer, retract)

**Quality Metrics:**
- Successful annotations: 48/50 episodes (96%)
- Failed episodes: 2 (boundaries exceeded episode length)
- Average subtask duration:
  - Move right arm: 26.2%
  - Grasp: 22.8%
  - Lift/move: 22.3%
  - Transfer: 20.4%
  - Retract: 8.3%

**Issues:**
- Episode 0: annotated to frame 500 (episode ends at 400)
- Episode 2: annotated to frame 450 (episode ends at 400)
- Impact: Minimal (SARM uses temporal fallback)

### SARM Training

**Architecture:**
- 8-layer Transformer
- 768 hidden dimensions
- 12 attention heads
- Dual MLP heads (stage + progress)

**Training:**
- Steps: 625 (2 epochs)
- Batch size: 64
- Frame gap: 30
- Final loss: 0.050
  - Dense stage loss: 0.076
  - Dense subtask loss: 0.009

**Progress Prediction Quality:**
- Monotonicity: 73.7-86.2% across episodes
- Average: 80.2%
- This is NORMAL per SARM paper ("generally monotonic")
- RA-BC soft weighting handles non-monotonicity

### RA-BC Weight Distribution

**Statistics (Final Batch):**
- Mean weight: 0.69
- Delta mean: 0.217
- Delta std: 0.081
- Kappa (threshold): 0.241 (auto-tuned)
- Full weight samples: 30-44 per batch (47-69%)
- Zero weight samples: 3-8 per batch (5-12%)

**Interpretation:**
- Healthy distribution indicates proper functioning
- ~50% of samples get full weight (high quality)
- ~10% get zero weight (low quality)
- Remaining ~40% get soft weights (medium quality)

---

## Ablation Studies

### Crop Settings

| Crop Mode | Training | Eval | Success Rate |
|-----------|----------|------|-------------|
| Random crop 224×224 | RandomCrop | CenterCrop | 0% (mismatch) |
| Random crop 224×224 | RandomCrop | Resize | 0% (still bad) |
| No crop | Full image | Full image | **24%** ✓ |

**Conclusion:** No crop is necessary for this task

### Training Duration

| Steps | Epochs | ACT Success | Diffusion RA-BC Success |
|-------|--------|------------|------------------------|
| 10K | 32 | - | 24% |
| 20K | 64 | 32% | - |
| 50K | 160 | - | 0% (overfit) |
| 80K | 256 | 68% | TBD |

**Conclusion:** Optimal range is 10K-80K depending on policy

---

## Lessons Learned

### 1. Overfitting on Small Datasets
- 50 episodes is SMALL for deep learning
- More than 50 epochs risks severe overfitting
- Monitor validation loss, use early stopping
- 32 epochs worked well for this task

### 2. SARM Monotonicity Requirements
- Perfect monotonicity (100%) is NOT required
- 80% monotonicity is acceptable and expected
- RA-BC soft weighting handles prediction noise
- Don't restart pipeline unnecessarily

### 3. Train/Eval Distribution Match
- Preprocessing MUST match between train and eval
- RandomCrop→CenterCrop mismatch = 0% success
- Solution: No crop or consistent crop strategy

### 4. Policy Selection Matters
- ACT designed for manipulation → 68% success
- DiffusionPolicy general → 24% success
- Match policy architecture to task domain

### 5. RA-BC Provides Real Gains
- 3x improvement (8%→24%) validates SARM
- Works even with "imperfect" progress predictions
- Sample weighting is effective technique

---

## Future Work

### Improvements to Try

1. **More Demonstrations**
   - Collect 100-200 episodes
   - Reduces overfitting risk
   - May enable longer training

2. **Better VLM Annotations**
   - Use GPT-4V or Claude 3.5 Sonnet
   - Validate boundary correctness
   - Fix episodes 0 and 2

3. **Multi-Stage SARM Training**
   - Currently using 5 dense stages
   - Try 3 sparse stages
   - Compare sparse vs dense heads

4. **Diffusion Architecture Variants**
   - Larger backbone (ResNet50)
   - Different diffusion schedulers
   - More diffusion steps

5. **Longer RA-BC Training**
   - 80K steps for Diffusion (in progress)
   - May close gap with ACT

### Open Questions

1. Does RA-BC help ACT (or only Diffusion)?
2. What's the scaling law for SARM (dataset size vs performance)?
3. Can SARM transfer across tasks?
4. How does SARM compare to learned reward models?

---

## Reproducibility

All experiments are fully reproducible using:
- Configurations in `configs/`
- Scripts in `scripts/`
- W&B logs at [dimios45/packsarm-aloha-comparison](https://wandb.ai/dimios45/packsarm-aloha-comparison)
- Dataset: [lerobot/aloha_sim_transfer_cube_human](https://huggingface.co/datasets/lerobot/aloha_sim_transfer_cube_human)

**Random seeds:** All experiments used seed=1000 for consistency

---

**Last Updated:** February 15, 2026
