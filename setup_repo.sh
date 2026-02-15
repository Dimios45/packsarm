#!/bin/bash
# Setup PACKSARM repository structure
set -e

echo "Setting up PACKSARM repository structure..."

# Create proper directory structure
mkdir -p {docs,configs,results,figures,notebooks}
mkdir -p docs/{papers,references}
mkdir -p results/{training,evaluation,comparison}
mkdir -p configs/{sarm,diffusion,act}

echo "✓ Directory structure created"

# Move existing results to organized structure
echo "Organizing results..."

# Training results
if [ -d "packsarm/outputs" ]; then
    cp -r packsarm/outputs/act_aloha_80k/training_metrics.jsonl results/training/act_80k_metrics.jsonl 2>/dev/null || true
    cp -r packsarm/outputs/act_aloha_20k/training_metrics.jsonl results/training/act_20k_metrics.jsonl 2>/dev/null || true
    cp -r packsarm/outputs/dp_aloha_bc_nocrop_10k/training_metrics.jsonl results/training/vanilla_bc_10k_metrics.jsonl 2>/dev/null || true
    cp -r packsarm/outputs/dp_aloha_rabc_nocrop_80k/training_metrics.jsonl results/training/rabc_80k_metrics.jsonl 2>/dev/null || true
    echo "  ✓ Training metrics copied"
fi

# Evaluation results
if [ -d "packsarm/outputs" ]; then
    cp packsarm/outputs/eval_act_80k/eval_info.json results/evaluation/act_80k_eval.json 2>/dev/null || true
    cp packsarm/outputs/eval_act_20k/eval_info.json results/evaluation/act_20k_eval.json 2>/dev/null || true
    cp packsarm/outputs/eval_bc_nocrop_10k/eval_info.json results/evaluation/vanilla_bc_10k_eval.json 2>/dev/null || true
    cp packsarm/outputs/eval_rabc_nocrop_10k/eval_info.json results/evaluation/rabc_10k_eval.json 2>/dev/null || true
    echo "  ✓ Evaluation results copied"
fi

# Copy configs
if [ -d "packsarm/outputs" ]; then
    cp packsarm/outputs/act_aloha_80k/checkpoints/last/pretrained_model/train_config.json configs/act/act_80k_config.json 2>/dev/null || true
    cp packsarm/outputs/dp_aloha_bc_nocrop_10k/checkpoints/last/pretrained_model/train_config.json configs/diffusion/vanilla_bc_10k_config.json 2>/dev/null || true
    echo "  ✓ Configs copied"
fi

# Copy scripts to root
cp packsarm/scripts/*.sh scripts/ 2>/dev/null || mkdir -p scripts && cp packsarm/scripts/*.sh scripts/ 2>/dev/null || true
cp packsarm/scripts/*.py scripts/ 2>/dev/null || true
echo "  ✓ Scripts organized"

echo ""
echo "✓ Repository structure setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the generated README.md"
echo "2. Run: git init"
echo "3. Run: git add ."
echo "4. Run: git commit -m 'Initial commit: SARM + RA-BC experiments'"
echo "5. Create GitHub repo and push"
