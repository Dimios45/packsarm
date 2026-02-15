#!/bin/bash
# Train DiffusionPolicy with RA-BC on ALOHA transfer cube
#
# Reward-Aligned Behavior Cloning: uses SARM progress to weight training samples.
# Frames showing more task progress get higher weight.
#
# Paper: "SARM: Stage-Aware Reward Modeling for Long Horizon Robot Manipulation"
# https://arxiv.org/abs/2509.25358
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc}"
NUM_STEPS="${2:-50000}"

RABC_PROGRESS="/home/sra/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

echo "==================================="
echo "Training DiffusionPolicy (RA-BC)"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS"
echo "Progress: $RABC_PROGRESS"
echo "==================================="

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: SARM progress file not found at $RABC_PROGRESS"
    echo "Run compute_rabc_weights.py first."
    exit 1
fi

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --policy.crop_shape='[224, 224]' \
    --policy.pretrained_backbone_weights=ResNet18_Weights.IMAGENET1K_V1 \
    --policy.use_group_norm=false \
    --dataset.image_transforms.enable=true \
    --use_rabc=true \
    --rabc_progress_path="$RABC_PROGRESS" \
    --rabc_head_mode=dense \
    --rabc_chunk_size=100 \
    --rabc_kappa=auto \
    --batch_size=64 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_rabc \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================="
echo "RA-BC Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
