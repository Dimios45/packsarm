# PACKSARM: Robot Manipulation with Stage-Aware Reward Modeling

Two complete robot manipulation projects implementing SARM (Stage-Aware Reward Modeling) for behavior cloning improvement.

**Authors:** SRA VJTI
**Contact:** tjgada_b24@ee.vjti.ac.in
**Institution:** Veermata Jijabai Technological Institute

---

## 📦 Projects

### 1. [Packing Task](./packing/) - WBCD-Packing-RoboTwin
Multi-object packing with dual SARM arms in RoboTwin simulation environment.

**Status:** Complete ✅
**Best Result:** 90% success rate (9/10 seeds)
**Key Achievement:** Pretrained ResNet18 + larger crop solved vision grounding

[→ Go to Packing Project](./packing/)

---

### 2. [ALOHA Transfer Cube](./aloha/) - Bimanual Manipulation
Cube transfer between two robot arms using ALOHA simulation.

**Status:** Complete ✅
**Best Result:** RA-BC 3x improvement over vanilla BC (24% vs 8%)
**Key Achievement:** Validated SARM pipeline, overfitting diagnosis, ACT comparison

[→ Go to ALOHA Project](./aloha/)

---

## 🎯 Quick Comparison

| Project | Environment | Task | Best Policy | Success Rate | Key Learning |
|---------|------------|------|-------------|--------------|--------------|
| **Packing** | RoboTwin | Multi-object packing | DiffusionPolicy v2b | **90%** (9/10) | Pretrained backbone critical |
| **ALOHA** | gym-aloha | Bimanual cube transfer | ACT (80K) | **68%** (34/50) | ACT > Diffusion for manipulation |
| **ALOHA** | gym-aloha | Same with RA-BC | RA-BC Diffusion (10K) | **24%** (12/50) | RA-BC gives **3x improvement** |

---

## 🏆 Key Results Summary

### Packing Task
- ✅ **90% success** with pretrained ResNet18 + crop_shape=[224,224]
- ✅ Fixed vision grounding issue (crop too small → objects not visible)
- ✅ SARM v2b with ImageNet weights generalizes better
- ✅ Solved overfitting with proper crop size

### ALOHA Task
- ✅ **RA-BC: 24% success** vs **Vanilla BC: 8%** (**3x improvement**)
- ✅ **ACT: 68% success** (state-of-the-art for bimanual tasks)
- ✅ Validated SARM pipeline (80% monotonicity is sufficient)
- ✅ Diagnosed overfitting (160 epochs → 0%, 32 epochs → 24%)
- ✅ Proved crop mismatch kills performance

---

## 🔬 Research Contributions

### 1. SARM Pipeline Validation
Both projects prove SARM's effectiveness:
- **Packing:** Progress-based sample weighting helps with multi-object complexity
- **ALOHA:** 3x improvement (RA-BC vs vanilla BC) validates reward modeling

### 2. Practical Debugging Methodology
- Vision grounding diagnostics (crop analysis)
- Overfitting detection (epoch budget management)
- Train/eval distribution mismatch identification

### 3. Policy Comparison Insights
- ACT superior for manipulation (action chunking + temporal encoding)
- DiffusionPolicy needs careful tuning (crop, epochs, backbone)
- Pretrained backbones critical for small datasets

### 4. Reproducible Baselines
- Complete configs, scripts, and results
- W&B logs for transparency
- Lessons learned documented

---

## 📁 Repository Structure

```
packsarm/
├── README.md                    # This file
├── .gitignore
├── requirements.txt
│
├── packing/                     # WBCD-Packing-RoboTwin project
│   ├── README.md               # Packing-specific docs
│   ├── scripts/                # Training/eval scripts
│   ├── config/                 # SARM configs
│   ├── results/                # Training logs, eval results
│   └── WBCD-Packing-RoboTwin/  # RoboTwin environment
│
├── aloha/                       # ALOHA transfer cube project
│   ├── README.md               # ALOHA-specific docs
│   ├── RESULTS.md              # Detailed experimental results
│   ├── scripts/                # Training/eval scripts
│   ├── configs/                # Model configurations
│   │   ├── sarm/
│   │   ├── diffusion/
│   │   └── act/
│   └── results/                # Training/eval data
│       ├── training/
│       ├── evaluation/
│       └── comparison/
│
└── lerobot/                     # LeRobot library (SARM integration)
    └── src/lerobot/
        ├── policies/sarm/
        └── data_processing/sarm_annotations/
```

---

## 🚀 Quick Start

### Install Dependencies

```bash
# Clone repository
git clone https://github.com/Dimios45/packsarm.git
cd packsarm

# Create virtual environment
python -m venv sarm-env
source sarm-env/bin/activate  # or `sarm-env\Scripts\activate` on Windows

# Install requirements
pip install -r requirements.txt

# Install LeRobot
cd lerobot && pip install -e . && cd ..
```

### Run Packing Task

```bash
cd packing
./scripts/train_policy_v2b.sh  # Best config (90% success)
```

See [packing/README.md](./packing/README.md) for details.

### Run ALOHA Task

```bash
cd aloha

# Train SARM reward model
./scripts/train_sarm_aloha.sh

# Train policy with RA-BC
./scripts/train_dp_aloha_rabc_nocrop.sh

# Evaluate
./scripts/eval_dp_aloha.sh <checkpoint_path> 50 <run_name>
```

See [aloha/README.md](./aloha/README.md) for details.

---

## 📊 W&B Dashboards

**Packing Task:**
- TBD (add W&B link for packing experiments)

**ALOHA Task:**
- [dimios45/packsarm-aloha-comparison](https://wandb.ai/dimios45/packsarm-aloha-comparison)

---

## 📚 Citations

### SARM Paper
```bibtex
@article{zhao2025sarm,
  title={Stage-Aware Reward Modeling for Long Horizon Robot Manipulation},
  author={Zhao, Tony Z. and others},
  journal={arXiv preprint arXiv:2509.25358},
  year={2025}
}
```

### DiffusionPolicy
```bibtex
@inproceedings{chi2023diffusion,
  title={Diffusion Policy: Visuomotor Policy Learning via Action Diffusion},
  author={Chi, Cheng and others},
  booktitle={Robotics: Science and Systems},
  year={2023}
}
```

### ACT (Action Chunking Transformer)
```bibtex
@article{zhao2023learning,
  title={Learning Fine-Grained Bimanual Manipulation with Low-Cost Hardware},
  author={Zhao, Tony Z. and others},
  journal={arXiv preprint arXiv:2304.13705},
  year={2023}
}
```

### RoboTwin
```bibtex
@article{wu2024robotwin,
  title={RoboTwin: Dual-Arm Robot Benchmark with Generative Digital Twins},
  author={Wu, Yao and others},
  journal={arXiv preprint},
  year={2024}
}
```

---

## 🤝 Acknowledgments

- **SARM Team** - Original paper and implementation
- **LeRobot** - HuggingFace robot learning library
- **RoboTwin** - Dual-arm simulation environment
- **ALOHA** - Bimanual manipulation platform
- **VJTI SRA** - Support and resources

---

## 📜 License

MIT License - See LICENSE file for details

---

## 📧 Contact

**Team:** SRA VJTI
**Email:** tjgada_b24@ee.vjti.ac.in
**GitHub:** [@Dimios45](https://github.com/Dimios45)
**W&B:** [dimios45](https://wandb.ai/dimios45)

---

## 🗺️ Roadmap

### Completed ✅
- [x] Packing task with SARM (90% success)
- [x] ALOHA task with RA-BC (3x improvement)
- [x] ACT baseline comparison
- [x] Overfitting diagnostics
- [x] Vision grounding fixes
- [x] Complete documentation

### In Progress 🔄
- [ ] RA-BC Diffusion 80K training (ALOHA)
- [ ] W&B dashboard for packing task

### Future Work 🔮
- [ ] Multi-stage SARM (sparse vs dense heads)
- [ ] Cross-task transfer experiments
- [ ] Real robot deployment (ALOHA hardware)
- [ ] Larger dataset collection (100+ episodes)
- [ ] Publication submission

---

## 🌟 Star History

If you find this work useful, please ⭐ star the repository!

---

**Last Updated:** February 2026
