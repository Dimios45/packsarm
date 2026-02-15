#!/bin/bash
# Train policy with crop fix + RA-BC weighting from SARM progress
#
# Phase 3: Full SARM integration. Requires sarm_progress.parquet to exist
# in the dataset directory. Run compute_rabc_weights.sh first:
#
#   ./compute_rabc_weights.sh \
#       /home/sra/packsarm/packsarm/outputs/sarm_wbcd_packing \
#       /home/sra/packsarm/packsarm/lerobot_dataset_fixed
#
# Usage: ./train_policy_v2_rabc.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Use the FIXED dataset with correct action labels
DATASET_DIR="${PROJECT_DIR}/lerobot_dataset_fixed"
OUTPUT_DIR="${PROJECT_DIR}/outputs/policy_v3_rabc"
RABC_PROGRESS="${DATASET_DIR}/sarm_progress.parquet"

echo "==================================="
echo "Training Policy v2 + RA-BC"
echo "Dataset:     $DATASET_DIR"
echo "RA-BC:       $RABC_PROGRESS"
echo "Output:      $OUTPUT_DIR"
echo "==================================="

# Check dataset exists
if [ ! -d "$DATASET_DIR" ]; then
    echo "Error: Dataset not found at $DATASET_DIR"
    exit 1
fi

# Check SARM progress file exists
if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: sarm_progress.parquet not found at $RABC_PROGRESS"
    echo "Run compute_rabc_weights.sh first to generate it."
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"
export HF_LEROBOT_HOME="${LEROBOT_DIR}"

# Train diffusion policy with crop fix + RA-BC weighting
python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --policy.crop_shape='[224, 224]' \
    --policy.pretrained_backbone_weights=ResNet18_Weights.IMAGENET1K_V1 \
    --policy.use_group_norm=false \
    --dataset.image_transforms.enable=true \
    --use_rabc=true \
    --rabc_progress_path="$RABC_PROGRESS" \
    --rabc_head_mode=sparse \
    --rabc_chunk_size=100 \
    --rabc_kappa=auto \
    --steps=50000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --batch_size=32 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/policy_v3_rabc_packing \
    --wandb.enable=false

echo "==================================="
echo "Policy v2 + RA-BC Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
