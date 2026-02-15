#!/bin/bash
# Train policy with RA-BC weighting from SARM
# Usage: ./train_policy_rabc.sh [dataset_dir] [output_dir] [policy_type]
#
# IMPORTANT: Activate sarm-env before running this script:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Default paths
DATASET_DIR="${1:-${PROJECT_DIR}/lerobot_dataset}"
OUTPUT_DIR="${2:-${PROJECT_DIR}/outputs/policy_rabc}"
POLICY_TYPE="${3:-diffusion}"  # diffusion, act, or vqbet

echo "==================================="
echo "Training Policy with RA-BC Weighting"
echo "Dataset:     $DATASET_DIR"
echo "Output:      $OUTPUT_DIR"
echo "Policy Type: $POLICY_TYPE"
echo "==================================="

# Check dataset and progress file exist
if [ ! -d "$DATASET_DIR" ]; then
    echo "Error: Dataset not found at $DATASET_DIR"
    exit 1
fi

PROGRESS_FILE="${DATASET_DIR}/sarm_progress.parquet"
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "Error: RA-BC progress file not found at $PROGRESS_FILE"
    echo "Please run compute_rabc_weights.sh first"
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

# Train policy with RA-BC weighting using draccus-based CLI
python -m lerobot.scripts.lerobot_train \
    --policy.type="$POLICY_TYPE" \
    --dataset.repo_id="$DATASET_DIR" \
    --dataset.root="$DATASET_DIR" \
    --use_rabc=true \
    --rabc_progress_path="$PROGRESS_FILE" \
    --rabc_head_mode=sparse \
    --rabc_kappa=0.01 \
    --steps=50000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --batch_size=32 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/policy_rabc_packing \
    --wandb.enable=false

echo "==================================="
echo "Policy Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
