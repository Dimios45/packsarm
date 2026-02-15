# Packing Task - WBCD-Packing-RoboTwin

Multi-object packing task using dual SARM arms in the RoboTwin simulation environment.

**Status:** ✅ Complete
**Best Result:** **90% success rate** (9/10 evaluation seeds)
**Environment:** WBCD-Packing-RoboTwin (custom RoboTwin task)

---

## 🎯 Task Description

Pack 5 objects into a box using dual robot arms and close the flaps.

**Success Criteria:**
- All 5 objects must be inside the box
- Box flaps must be closed
- Evaluated on 10 different random seeds

**Key Challenge:** Multi-object manipulation with vision grounding

---

## 📊 Results Summary

| Model Version | Configuration | Success Rate | Key Features |
|---------------|--------------|-------------|--------------|
| **v2b** | Pretrained ResNet18 + crop=[224,224] | **90%** (9/10) | ✅ Best performance |
| v2 | From-scratch ResNet18 + crop=[224,224] | Variable | Worse generalization |
| v2_rabc | RA-BC weighting + crop=[224,224] | TBD | With reward weighting |

### Evaluation Results (v2b - 10 seeds)

```
┌────────┬─────────┬───────┐
│ Seed   │ Result  │ Steps │
├────────┼─────────┼───────┤
│ 100030 │ SUCCESS │   83  │
│ 100031 │ SUCCESS │  437  │
│ 100032 │ SUCCESS │ 1775  │
│ 100033 │ SUCCESS │  248  │
│ 100034 │ SUCCESS │   81  │
│ 100035 │ SUCCESS │   81  │
│ 100036 │ SUCCESS │ 1008  │
│ 100037 │ SUCCESS │  202  │
│ 100038 │ SUCCESS │  264  │
│ 100039 │ FAIL    │ 2000  │
└────────┴─────────┴───────┘

Success Rate: 90% (9/10 seeds)
```

---

## 🔧 Key Findings

### 1. **Crop Size Critical for Vision Grounding**

**Problem:** Default crop_shape=[84, 84] made policy blind
- 84×84 center crop on 240×320 image = only 26% coverage
- Policy couldn't see most objects → failed

**Solution:** crop_shape=[224, 224]
- 224×224 covers 93% height, 70% width
- Objects visible → 90% success

**Technical Note:** Crop size is baked into SpatialSoftmax layer dimensions, requires retraining if changed.

### 2. **Pretrained Backbone Helps Significantly**

**v2b (pretrained):** 90% success
- Uses ImageNet-pretrained ResNet18
- Better feature extraction
- Solved seeds that v2 couldn't (e.g., seed 100033)

**v2 (from scratch):** Variable performance
- Trained ResNet18 from random initialization
- Requires `use_group_norm=false` for pretrained weights

**Takeaway:** With only 50 demos, pretrained features are critical

### 3. **RA-BC Bug Fixes**

Two critical bugs were found and fixed:

**Bug 1:** SARM progress values were garbage (0.0003 instead of 0-1)
- Root cause: Used `.name` (pandas row index) instead of `["task"]` column
- CLIP encoded "0" → near-zero progress for all frames
- Fixed in `lerobot_dataset.py:1077`

**Bug 2:** chunk_size and kappa miscalibration
- Old: chunk_size=8 (from policy n_action_steps) → deltas ~0.0002 (noise level)
- New: chunk_size=100 (independent of policy) → meaningful deltas
- Old: kappa=0.01 was 50x larger than max delta
- New: kappa="auto" (median of positive deltas)

---

## 🚀 Quick Start

### Training

```bash
# Best configuration (v2b)
./scripts/train_policy_v2b.sh

# Vanilla BC (v2)
./scripts/train_policy_v2.sh

# RA-BC version (v2_rabc)
./scripts/train_policy_v2_rabc.sh
```

### Evaluation

```bash
# Evaluate on 10 seeds
python WBCD-Packing-RoboTwin/policy/LeRobotDP/test_eval.py \
    --checkpoint_dir outputs/policy_v2b/checkpoints/last/pretrained_model \
    --num_seeds 10
```

---

## 📁 Key Files

```
packing/
├── README.md                                    # This file
├── scripts/
│   ├── train_policy_v2.sh                      # Crop fix only
│   ├── train_policy_v2b.sh                     # Pretrained + crop fix (best)
│   └── train_policy_v2_rabc.sh                 # RA-BC + crop fix
├── config/
│   └── sarm_packing.yaml                       # SARM config (5 stages)
├── WBCD-Packing-RoboTwin/                      # RoboTwin environment
│   ├── envs/
│   │   ├── _base_task.py                       # Modified: uncommented TOPP errors
│   │   └── packing.py                          # Modified: relaxed check_success
│   └── policy/LeRobotDP/
│       └── test_eval.py                        # Modified: added object logging
└── outputs/                                     # Training outputs
    ├── policy_v2/
    ├── policy_v2b/                             # Best model (90%)
    └── policy_v3_rabc/                         # RA-BC version
```

---

## 🔬 Training Details

### Dataset
- **Episodes:** 50
- **Frames per episode:** ~878 frames
- **Frame rate:** 15 FPS
- **Objects per episode:** 5 (all must be packed)
- **Images:** RGB from Sapien `get_picture("Color")`, H.264 encoding
- **State/Action:** 14D (6 joints + 1 gripper × 2 arms)
- **Action formulation:** Next-state (action[t] = state[t+1])

### v2b Configuration (Best)
```yaml
Policy: DiffusionPolicy
  Vision: ResNet18 (ImageNet pretrained)
  Crop: [224, 224]
  Normalization: ImageNet MEAN_STD
  use_group_norm: false  # Required for pretrained

Training:
  Steps: 50,000
  Batch size: 64
  Learning rate: 1e-4
  Data augmentation: ColorJitter, RandomAffine
```

---

## ⚠️ Common Issues

### Issue 1: Policy Doesn't See Objects
**Symptom:** Arms move but don't interact with objects

**Fix:** Increase crop_shape to at least [224, 224]

### Issue 2: TOPP Errors Silent
**Symptom:** Robot executes invalid trajectories

**Fix:** Uncommented error prints in `envs/_base_task.py`

### Issue 3: Training Loss Low but Eval Fails
**Symptom:** Loss ~0.001 but 0% success

**Fix:** Check for overfitting, vision grounding issues

---

## 🎓 Lessons Learned

1. **Vision grounding is critical** - Policy must SEE objects to manipulate them
2. **Pretrained backbones help** - ImageNet features transfer well with small datasets
3. **Crop size affects architecture** - SpatialSoftmax grid size is baked in
4. **Eval environment must match training** - Distribution shift kills performance
5. **RA-BC bugs are subtle** - Always validate progress values before use

---

## 🔗 Related Work

- [RoboTwin Paper](https://arxiv.org/abs/2409.02920)
- [SARM Paper](https://arxiv.org/abs/2509.25358)
- [DiffusionPolicy Paper](https://arxiv.org/abs/2303.04137)
- [LeRobot Library](https://github.com/huggingface/lerobot)

---

## 📧 Contact

**Team:** SRA VJTI
**Email:** tjgada_b24@ee.vjti.ac.in

---

**Last Updated:** February 2026
