#!/bin/bash
# Train policy with FIXED crop size (224x224 instead of default 84x84)
#
# The default 84x84 crop makes the policy blind at eval time — center crop
# covers only 26% of the 240x320 input image, missing most objects.
# 224x224 gives a 7x7 ResNet18 feature map (vs 3x3) and preserves 93% height / 70% width.
#
# Usage: ./train_policy_v2.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Use the FIXED dataset with correct action labels
DATASET_DIR="${PROJECT_DIR}/lerobot_dataset_fixed"
OUTPUT_DIR="${PROJECT_DIR}/outputs/policy_v2"

echo "==================================="
echo "Training Policy v2 (crop_shape=224x224)"
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

# Train diffusion policy with 224x224 crop (critical fix)
python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --policy.crop_shape='[224, 224]' \
    --use_rabc=false \
    --steps=50000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --batch_size=32 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/policy_v2_packing \
    --wandb.enable=false

echo "==================================="
echo "Policy v2 Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
