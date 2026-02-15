#!/bin/bash
# Train policy with crop fix + ImageNet-pretrained ResNet18 backbone + augmentation
#
# Phase 2 fallback: if Phase 1 (v2) doesn't succeed, the pretrained backbone
# helps with only 50 episodes — the model doesn't need to learn visual features
# from scratch.
#
# Note: use_group_norm=false is required because pretrained ResNet18 uses
# BatchNorm and GroupNorm replacement would break the loaded weights.
#
# Usage: ./train_policy_v2b.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Use the FIXED dataset with correct action labels
DATASET_DIR="${PROJECT_DIR}/lerobot_dataset_fixed"
OUTPUT_DIR="${PROJECT_DIR}/outputs/policy_v2b"

echo "==================================="
echo "Training Policy v2b (pretrained backbone + augmentation)"
echo "Dataset:     $DATASET_DIR"
echo "Output:      $OUTPUT_DIR"
echo "==================================="

# Check dataset exists
if [ ! -d "$DATASET_DIR" ]; then
    echo "Error: Dataset not found at $DATASET_DIR"
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"
export HF_LEROBOT_HOME="${LEROBOT_DIR}"

# Train diffusion policy with pretrained backbone
python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --policy.crop_shape='[224, 224]' \
    --policy.pretrained_backbone_weights=ResNet18_Weights.IMAGENET1K_V1 \
    --policy.use_group_norm=false \
    --dataset.image_transforms.enable=true \
    --use_rabc=false \
    --steps=50000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --batch_size=32 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/policy_v2b_packing \
    --wandb.enable=false

echo "==================================="
echo "Policy v2b Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
