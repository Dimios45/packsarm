#!/bin/bash
# Train policy on FIXED dataset (correct action labels)
# Usage: ./train_policy_fixed.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Use the FIXED dataset with correct action labels
DATASET_DIR="${PROJECT_DIR}/lerobot_dataset_fixed"
OUTPUT_DIR="${PROJECT_DIR}/outputs/policy_fixed"

echo "==================================="
echo "Training Policy on FIXED Dataset"
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

# Train diffusion policy without RABC (vanilla BC on fixed data)
python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --use_rabc=false \
    --steps=50000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --batch_size=32 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/policy_fixed_packing \
    --wandb.enable=false

echo "==================================="
echo "Policy Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
