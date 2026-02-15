#!/bin/bash
# Train DiffusionPolicy with RA-BC (80K steps) on ALOHA transfer cube
#
# Testing if more training can match ACT performance:
# - ACT 80K: 68% success
# - RA-BC Diffusion 10K: 24% success
# - Goal: See if 80K steps improves RA-BC Diffusion significantly
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc_nocrop_80k}"
RABC_PROGRESS="${HOME}/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

echo "==================================="
echo "Training DiffusionPolicy with RA-BC (80K steps, NO CROP)"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    80,000 (256 epochs)"
echo "RA-BC:    $RABC_PROGRESS"
echo "Baseline: 24% @ 10K steps"
echo "Target:   Match ACT scaling (32%→68%)"
echo "==================================="

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: RA-BC progress file not found: $RABC_PROGRESS"
    exit 1
fi

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=diffusion \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --policy.crop_shape=null \
    --policy.crop_is_random=false \
    --policy.pretrained_backbone_weights=ResNet18_Weights.IMAGENET1K_V1 \
    --policy.use_group_norm=false \
    --dataset.image_transforms.enable=true \
    --use_rabc=true \
    --rabc_progress_path="$RABC_PROGRESS" \
    --rabc_head_mode=dense \
    --rabc_chunk_size=100 \
    --rabc_kappa=auto \
    --rabc_epsilon=1e-6 \
    --batch_size=64 \
    --steps=80000 \
    --eval_freq=0 \
    --save_freq=20000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_rabc_nocrop_80k \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================="
echo "RA-BC Diffusion Training Complete (80K steps)!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
