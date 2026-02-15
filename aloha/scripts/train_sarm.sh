#!/bin/bash
# Train SARM (Stage-Aware Reward Model) on packing demonstrations
# Usage: ./train_sarm.sh [dataset_dir] [output_dir] [num_steps]
#
# Uses single_stage mode: the progress head learns a monotonic 0→1 signal
# over the episode, which RA-BC uses to weight frames (later frames = higher weight).
#
# IMPORTANT: Activate sarm-env before running this script:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Default paths — use FIXED dataset
DATASET_DIR="${1:-${PROJECT_DIR}/lerobot_dataset_fixed}"
OUTPUT_DIR="${2:-${PROJECT_DIR}/outputs/sarm_wbcd_packing}"
NUM_STEPS="${3:-5000}"

echo "==================================="
echo "Training SARM Reward Model"
echo "Dataset:  $DATASET_DIR"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS"
echo "==================================="

# Check dataset exists
if [ ! -d "$DATASET_DIR" ]; then
    echo "Error: Dataset not found at $DATASET_DIR"
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

# Train SARM with single_stage annotation
python -m lerobot.scripts.lerobot_train \
    --policy.type=sarm \
    --policy.annotation_mode=single_stage \
    --policy.n_obs_steps=8 \
    --policy.frame_gap=2 \
    --policy.max_rewind_steps=4 \
    --policy.hidden_dim=768 \
    --policy.num_heads=12 \
    --policy.num_layers=8 \
    --policy.image_key=observation.images.top \
    --policy.state_key=observation.state \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --batch_size=32 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=1000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/sarm_wbcd_packing \
    --wandb.enable=false

echo "==================================="
echo "SARM Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
