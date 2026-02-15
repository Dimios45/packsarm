#!/bin/bash
# Organize repository with both Packing and ALOHA projects
set -e

echo "============================================================"
echo "Organizing PACKSARM repository (Packing + ALOHA)"
echo "============================================================"

# Create main structure
mkdir -p aloha/{scripts,configs,results,docs}
mkdir -p aloha/results/{training,evaluation,comparison}
mkdir -p aloha/configs/{sarm,diffusion,act}
mkdir -p packing  # Keep existing packing work here

echo "✓ Directory structure created"

# Move ALOHA-specific files
echo "Moving ALOHA files..."

# Scripts
if [ -d "packsarm/scripts" ]; then
    cp packsarm/scripts/train_sarm_aloha.sh aloha/scripts/ 2>/dev/null || true
    cp packsarm/scripts/train_dp_aloha*.sh aloha/scripts/ 2>/dev/null || true
    cp packsarm/scripts/train_act_aloha.sh aloha/scripts/ 2>/dev/null || true
    cp packsarm/scripts/eval_dp_aloha.sh aloha/scripts/ 2>/dev/null || true
    cp packsarm/scripts/upload_to_wandb.py aloha/scripts/ 2>/dev/null || true
    echo "  ✓ Scripts copied"
fi

# Training results
if [ -d "packsarm/outputs" ]; then
    # ACT results
    cp packsarm/outputs/act_aloha_80k/training_metrics.jsonl aloha/results/training/act_80k.jsonl 2>/dev/null || true
    cp packsarm/outputs/act_aloha_20k/training_metrics.jsonl aloha/results/training/act_20k.jsonl 2>/dev/null || true

    # Diffusion results
    cp packsarm/outputs/dp_aloha_bc_nocrop_10k/training_metrics.jsonl aloha/results/training/vanilla_bc_10k.jsonl 2>/dev/null || true
    cp packsarm/outputs/dp_aloha_rabc_nocrop_80k/training_metrics.jsonl aloha/results/training/rabc_80k.jsonl 2>/dev/null || true

    # SARM results
    cp packsarm/outputs/sarm_aloha_v2/training_metrics.jsonl aloha/results/training/sarm_v2.jsonl 2>/dev/null || true

    echo "  ✓ Training results copied"
fi

# Evaluation results
if [ -d "packsarm/outputs" ]; then
    cp packsarm/outputs/eval_act_80k/eval_info.json aloha/results/evaluation/act_80k.json 2>/dev/null || true
    cp packsarm/outputs/eval_act_20k/eval_info.json aloha/results/evaluation/act_20k.json 2>/dev/null || true
    cp packsarm/outputs/eval_bc_nocrop_10k/eval_info.json aloha/results/evaluation/vanilla_bc_10k.json 2>/dev/null || true
    cp packsarm/outputs/eval_rabc_nocrop_10k/eval_info.json aloha/results/evaluation/rabc_10k.json 2>/dev/null || true
    echo "  ✓ Evaluation results copied"
fi

# Configs
if [ -d "packsarm/outputs" ]; then
    cp packsarm/outputs/act_aloha_80k/checkpoints/last/pretrained_model/train_config.json aloha/configs/act/act_80k.json 2>/dev/null || true
    cp packsarm/outputs/dp_aloha_bc_nocrop_10k/checkpoints/last/pretrained_model/train_config.json aloha/configs/diffusion/vanilla_bc_10k.json 2>/dev/null || true
    echo "  ✓ Configs copied"
fi

# Create .gitkeep files to preserve directory structure
find aloha packing -type d -empty -exec touch {}/.gitkeep \; 2>/dev/null || true

echo ""
echo "============================================================"
echo "✓ Repository organized!"
echo "============================================================"
echo ""
echo "Structure:"
echo "  packsarm/"
echo "    ├── README.md (main - covers both projects)"
echo "    ├── packing/ (WBCD-Packing-RoboTwin work)"
echo "    │   ├── README.md"
echo "    │   └── ... (existing files)"
echo "    └── aloha/ (ALOHA transfer cube work)"
echo "        ├── README.md"
echo "        ├── scripts/"
echo "        ├── configs/"
echo "        └── results/"
echo ""
echo "Next steps:"
echo "1. Review the new README files"
echo "2. Move existing packing files to packing/ directory"
echo "3. git add ."
echo "4. git commit -m 'Organize: Separate packing and ALOHA projects'"
echo "5. git push"
