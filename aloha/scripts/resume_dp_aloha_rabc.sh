#!/bin/bash
# Resume DiffusionPolicy RA-BC training from checkpoint
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

CHECKPOINT_DIR="${SCRIPT_DIR}/../outputs/dp_aloha_rabc/checkpoints/last/pretrained_model"
OUTPUT_DIR="${SCRIPT_DIR}/../outputs/dp_aloha_rabc"
NUM_STEPS="${1:-50000}"

RABC_PROGRESS="/home/sra/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

echo "==================================="
echo "Resuming DiffusionPolicy (RA-BC) Training"
echo "Checkpoint: $CHECKPOINT_DIR"
echo "Target:     $NUM_STEPS steps"
echo "Output:     $OUTPUT_DIR"
echo "==================================="

if [ ! -d "$CHECKPOINT_DIR" ]; then
    echo "Error: Checkpoint not found at $CHECKPOINT_DIR"
    exit 1
fi

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --config_path="$CHECKPOINT_DIR/train_config.json" \
    --resume=true \
    --steps="$NUM_STEPS"

echo "==================================="
echo "RA-BC Training Resumed & Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
