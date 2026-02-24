#!/bin/bash
# Train ACT with RA-BC on ALOHA transfer cube
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/act_aloha_rabc}"
NUM_STEPS="${2:-20000}"

RABC_PROGRESS="/home/sra/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: RA-BC progress file not found: $RABC_PROGRESS"
    exit 1
fi

echo "==================================="
echo "Training ACT with RA-BC"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=act \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --use_rabc=true \
    --rabc_progress_path="$RABC_PROGRESS" \
    --rabc_head_mode="${RABC_HEAD_MODE:-dense}" \
    --rabc_chunk_size=100 \
    --rabc_kappa="${RABC_KAPPA:-0.01}" \
    --rabc_epsilon=1e-6 \
    --batch_size=8 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=5000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/act_aloha_rabc \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================="
echo "ACT RA-BC Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
