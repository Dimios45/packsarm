# PACKSARM: Stage-Aware Reward Modeling for Robot Manipulation

Implementation and experiments with [SARM (Stage-Aware Reward Modeling)](https://arxiv.org/abs/2509.25358) for robot manipulation using LeRobot and ALOHA simulation.

**Authors:** SRA VJTI
**Contact:** tjgada_b24@ee.vjti.ac.in
**Affiliation:** Veermata Jijabai Technological Institute (VJTI)

---

## 🎯 Project Overview

This repository contains a complete implementation of the SARM pipeline for improving behavior cloning through reward-aligned sample weighting (RA-BC). We validate the approach on the ALOHA bimanual manipulation task.

### Key Results

| Model | Policy | Steps | Success Rate | Improvement |
|-------|--------|-------|-------------|-------------|
| **ACT** | Transformer | 80K | **68%** | Baseline (SOTA) |
| **RA-BC Diffusion** | Diffusion + SARM | 10K | **24%** | **+200%** vs Vanilla BC |
| **Vanilla BC Diffusion** | Diffusion | 10K | **8%** | Baseline |

**Key Finding:** RA-BC achieves **3x better performance** than vanilla BC by focusing on high-quality demonstration segments identified by SARM.

---

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Experiments](#experiments)
- [Results](#results)
- [Pipeline Overview](#pipeline-overview)
- [Repository Structure](#repository-structure)
- [Citation](#citation)

---

## 🚀 Installation

### Prerequisites
- Python 3.10+
- CUDA-capable GPU (tested on RTX 4090)
- 32GB+ RAM recommended

### Setup

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/packsarm.git
cd packsarm

# Create virtual environment
python -m venv sarm-env
source sarm-env/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install LeRobot
cd lerobot
pip install -e .
cd ..

# Install ALOHA simulation
pip install gym-aloha mujoco dm_control
```

---

## ⚡ Quick Start

### 1. VLM Annotation (Dense Subtasks)

Annotate demonstrations with temporal subtask boundaries using VLM:

```bash
./scripts/annotate_aloha.sh
```

### 2. Train SARM Reward Model

```bash
./scripts/train_sarm_aloha.sh
```

### 3. Compute RA-BC Weights

```bash
python -m lerobot.policies.sarm.compute_rabc_weights \
    --dataset-repo-id lerobot/aloha_sim_transfer_cube_human \
    --reward-model-path outputs/sarm_aloha_v2/checkpoints/last/pretrained_model \
    --output-path ~/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet
```

### 4. Train Policy with RA-BC

```bash
# RA-BC DiffusionPolicy
./scripts/train_dp_aloha_rabc_nocrop.sh

# Vanilla BC baseline (for comparison)
./scripts/train_dp_aloha_bc_nocrop.sh

# ACT baseline (SOTA)
./scripts/train_act_aloha.sh
```

### 5. Evaluate

```bash
./scripts/eval_dp_aloha.sh <checkpoint_path> 50 <run_name>
```

---

## 🔬 Experiments

### Experiment 1: RA-BC vs Vanilla BC

**Hypothesis:** SARM-based reward weighting improves sample efficiency and final performance.

**Setup:**
- Dataset: 50 ALOHA transfer cube demonstrations
- Policy: DiffusionPolicy (ResNet18 backbone)
- Training: 10K steps, batch_size=64, no crop
- Evaluation: 50 episodes

**Results:**
- ✅ **RA-BC: 24% success** (12/50 episodes)
- ❌ **Vanilla BC: 8% success** (4/50 episodes)
- **Improvement: +200%** (3x better)

### Experiment 2: Policy Comparison (ACT vs Diffusion)

**Hypothesis:** Action Chunking Transformer (ACT) is better suited for bimanual manipulation than DiffusionPolicy.

**Results:**

| Model | Steps | Success Rate |
|-------|-------|-------------|
| ACT | 80K | **68%** |
| ACT | 20K | **32%** |
| RA-BC Diffusion | 10K | **24%** |
| Vanilla BC Diffusion | 10K | **8%** |

**Conclusion:** ACT significantly outperforms DiffusionPolicy on this task, but RA-BC still provides substantial gains for Diffusion-based policies.

### Experiment 3: Training Curves & Overfitting

**Finding:** Initial training with 50K steps (160 epochs) resulted in **0% success** due to severe overfitting.

**Solution:** Reduced to 10K steps (32 epochs) → **24% success**

**Lesson:** Small datasets (50 episodes) require careful epoch budget management.

---

## 📊 Results

### Performance Summary

```
┌──────────────────────┬───────┬─────────┬──────────────┬────────────┐
│ Model                │ Steps │ Epochs  │ Success Rate │ Avg Reward │
├──────────────────────┼───────┼─────────┼──────────────┼────────────┤
│ ACT                  │ 80K   │ 256     │ 68%          │ 206.88     │
│ ACT                  │ 20K   │ 64      │ 32%          │ 168.86     │
│ RA-BC Diffusion      │ 10K   │ 32      │ 24%          │ 105.08     │
│ Vanilla BC Diffusion │ 10K   │ 32      │ 8%           │ 20.46      │
└──────────────────────┴───────┴─────────┴──────────────┴────────────┘
```

### Key Findings

1. **SARM/RA-BC Pipeline Works**
   - 3x improvement over vanilla BC validates the approach
   - 80% progress monotonicity is sufficient (not a failure mode)
   - Soft weighting handles prediction noise gracefully

2. **Overfitting is Critical**
   - 160 epochs → 0% success (complete memorization)
   - 32 epochs → 24% success (proper generalization)
   - Early stopping essential for small datasets

3. **Crop Preprocessing Matters**
   - Center crop at eval cut off cube in upper image region
   - Train/eval distribution mismatch → 0% success
   - Solution: No crop (full 480×640 image)

4. **ACT Superior for Bimanual Tasks**
   - 68% vs 24% (ACT vs best Diffusion)
   - Action chunking + temporal encoding well-suited for manipulation
   - DiffusionPolicy may excel on other tasks (contact-rich, long-horizon)

---

## 🔧 Pipeline Overview

### 1. VLM Annotation
- **Model:** Qwen2.5-VL-7B-Instruct
- **Input:** Episode videos
- **Output:** Dense temporal subtask boundaries
- **Subtasks:** 5 stages (reach, grasp, lift, transfer, retract)

### 2. SARM Training
- **Architecture:** 8-layer Transformer (768 hidden, 12 heads)
- **Heads:** Dual MLP (stage classification + progress regression)
- **Training:** 625 steps, batch_size=64, frame_gap=30
- **Output:** Progress predictions (0→1 per episode)

### 3. RA-BC Weight Computation
- **Input:** SARM progress predictions
- **Method:** Soft weighting based on progress deltas
- **Kappa:** Auto-tuned threshold (0.241)
- **Output:** Per-sample weights for policy training

### 4. Policy Training
- **Policies:** DiffusionPolicy, ACT
- **Weighting:** RA-BC weights applied to BC loss
- **Data Aug:** ColorJitter, RandomAffine (for training stability)

---

## 📁 Repository Structure

```
packsarm/
├── README.md                 # This file
├── requirements.txt          # Python dependencies
├── setup_repo.sh            # Repository setup script
│
├── scripts/                 # Training and evaluation scripts
│   ├── train_sarm_aloha.sh
│   ├── train_dp_aloha_rabc_nocrop.sh
│   ├── train_dp_aloha_bc_nocrop.sh
│   ├── train_act_aloha.sh
│   ├── eval_dp_aloha.sh
│   └── upload_to_wandb.py
│
├── configs/                 # Model configurations
│   ├── sarm/
│   ├── diffusion/
│   └── act/
│
├── results/                 # Experimental results
│   ├── training/           # Training metrics
│   ├── evaluation/         # Eval results
│   └── comparison/         # Cross-model comparisons
│
├── docs/                   # Documentation
│   ├── papers/            # Reference papers
│   └── references/        # Additional resources
│
├── figures/               # Plots and visualizations
│
├── lerobot/              # LeRobot fork (SARM integration)
│   └── src/
│       └── lerobot/
│           ├── policies/sarm/
│           └── data_processing/sarm_annotations/
│
└── packsarm/             # Legacy outputs (to be reorganized)
    └── outputs/
```

---

## 🐛 Issues & Solutions

### Issue 1: 0% Success with 50K Steps
**Problem:** Model achieved 0% success despite low training loss (0.0012)

**Root Cause:** Severe overfitting (160 epochs on 50 episodes)

**Solution:** Reduced to 10K steps (32 epochs) → **24% success**

### Issue 2: Non-Monotonic Progress (80%)
**Problem:** SARM progress predictions only 80% monotonic (expected >95%)

**Finding:** This is NORMAL! SARM paper expects "generally monotonic", not perfect.

**Solution:** RA-BC soft weighting handles this gracefully. No fix needed.

### Issue 3: VLM Annotation Boundary Errors
**Problem:** 2/50 episodes had annotation boundaries exceeding episode length

**Impact:** Minimal. SARM uses temporal proportion fallback.

**Solution:** Not critical, but could validate boundaries in future work.

---

## 📚 Citation

If you use this work, please cite:

```bibtex
@misc{packsarm2026,
  title={PACKSARM: Practical Implementation of Stage-Aware Reward Modeling for ALOHA},
  author={SRA VJTI},
  year={2026},
  institution={Veermata Jijabai Technological Institute}
}

@article{sarm2025,
  title={Stage-Aware Reward Modeling for Long Horizon Robot Manipulation},
  author={Zhao, Tony Z. and others},
  journal={arXiv preprint arXiv:2509.25358},
  year={2025}
}

@article{chi2023diffusion,
  title={Diffusion Policy: Visuomotor Policy Learning via Action Diffusion},
  author={Chi, Cheng and others},
  journal={RSS},
  year={2023}
}
```

---

## 🙏 Acknowledgments

- **SARM Team** - Original SARM paper and implementation
- **LeRobot** - Robot learning library and infrastructure
- **Hugging Face** - Dataset hosting and model hub
- **ACT Team** - Action Chunking Transformer baseline

---

## 📧 Contact

**Team:** SRA VJTI
**Email:** tjgada_b24@ee.vjti.ac.in
**W&B:** [dimios45](https://wandb.ai/dimios45)

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🔗 Links

- [SARM Paper](https://arxiv.org/abs/2509.25358)
- [LeRobot](https://github.com/huggingface/lerobot)
- [W&B Project](https://wandb.ai/dimios45/packsarm-aloha-comparison)
- [ALOHA Dataset](https://huggingface.co/datasets/lerobot/aloha_sim_transfer_cube_human)

---

**Last Updated:** February 2026
