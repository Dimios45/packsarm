#!/bin/bash
# Train ACT (Action Chunking Transformer) on ALOHA transfer cube
#
# Baseline from LeRobot: 83% success rate with 80K steps (~1h45 on A100)
# Reference: https://huggingface.co/lerobot/act_aloha_sim_transfer_cube_human
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/act_aloha_transfer}"
NUM_STEPS="${2:-80000}"

echo "==================================="
echo "Training ACT Policy"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS"
echo "Expected: ~1h45 training, 83% success"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=act \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --dataset.image_transforms.enable=true \
    --batch_size=8 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=20000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/act_aloha_transfer \
    --policy.push_to_hub=false \
    --wandb.enable=false \
    --policy.device=cuda \
    --policy.use_amp=false

echo "==================================="
echo "ACT Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
