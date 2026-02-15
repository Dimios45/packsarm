#!/bin/bash
# Compute RA-BC weights using trained SARM model
# Usage: ./compute_rabc_weights.sh [sarm_model_dir] [dataset_dir] [output_dir]
#
# IMPORTANT: Activate sarm-env before running this script:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

SARM_MODEL="${1:-${PROJECT_DIR}/outputs/sarm_wbcd_packing}"
DATASET_DIR="${2:-${PROJECT_DIR}/lerobot_dataset}"
OUTPUT_DIR="${3:-${PROJECT_DIR}/outputs/rabc_visualizations}"

echo "==================================="
echo "Computing RA-BC Weights"
echo "SARM Model: $SARM_MODEL"
echo "Dataset:    $DATASET_DIR"
echo "Output:     $OUTPUT_DIR"
echo "==================================="

# Find the latest checkpoint directory
if [ -d "$SARM_MODEL/checkpoints" ]; then
    LATEST_CKPT=$(ls -d ${SARM_MODEL}/checkpoints/*/pretrained_model 2>/dev/null | sort -V | tail -1)
    if [ -n "$LATEST_CKPT" ]; then
        SARM_MODEL="$LATEST_CKPT"
    fi
elif [ -d "$SARM_MODEL" ]; then
    LATEST_CKPT=$(ls -d ${SARM_MODEL}/checkpoint_* 2>/dev/null | sort -V | tail -1)
    if [ -n "$LATEST_CKPT" ]; then
        SARM_MODEL="$LATEST_CKPT"
    fi
fi

echo "Using checkpoint: $SARM_MODEL"

# Check SARM model exists
if [ ! -d "$SARM_MODEL" ]; then
    echo "Error: SARM model not found at $SARM_MODEL"
    echo "Please run train_sarm.sh first"
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

# Compute progress values for all episodes
python -m lerobot.policies.sarm.compute_rabc_weights \
    --reward-model-path "$SARM_MODEL" \
    --dataset-repo-id "$DATASET_DIR" \
    --dataset-root "$DATASET_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --head-mode sparse \
    --num-visualizations 3

echo "==================================="
echo "RA-BC Weight Computation Complete!"
echo "Progress file: ${DATASET_DIR}/sarm_progress.parquet"
echo "Visualizations: $OUTPUT_DIR"
echo "==================================="
