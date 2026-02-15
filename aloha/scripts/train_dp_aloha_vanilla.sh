#!/bin/bash
# Train vanilla DiffusionPolicy (BC baseline) on ALOHA transfer cube
#
# Standard behavior cloning without reward weighting.
# Used as baseline to compare against RA-BC.
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_vanilla}"
NUM_STEPS="${2:-50000}"

echo "==================================="
echo "Training DiffusionPolicy (Vanilla BC)"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --policy.crop_shape='[224, 224]' \
    --policy.pretrained_backbone_weights=ResNet18_Weights.IMAGENET1K_V1 \
    --policy.use_group_norm=false \
    --dataset.image_transforms.enable=true \
    --use_rabc=false \
    --batch_size=64 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_vanilla \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================="
echo "Vanilla BC Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
