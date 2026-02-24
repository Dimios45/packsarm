#!/bin/bash
# Train RA-BC DiffusionPolicy for 20K steps with PROPER LR schedule
#
# Key fix: Learning rate schedule configured for 20K steps (not 80K!)
# This ensures proper convergence like the successful 10K run
#
# Expected: Should achieve 15-25% success (similar to 10K)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc_nocrop_20k_fixed}"
RABC_PROGRESS="${HOME}/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

echo "==================================="
echo "Training RA-BC Diffusion (20K steps, FIXED LR schedule)"
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    20,000 (64 epochs)"
echo "LR Schedule: Cosine decay over 20K steps (NOT 80K!)"
echo "Fix: Proper convergence to match 10K success"
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
    --steps=20000 \
    --eval_freq=0 \
    --save_freq=5000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_rabc_nocrop_20k_fixed \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================="
echo "RA-BC Diffusion Training Complete (20K steps, FIXED)!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo ""
echo "Key difference from failed 80K run:"
echo "- LR schedule: 20K steps (not 80K)"
echo "- LR will decay to near-zero by 20K"
echo "- Should achieve similar performance to 10K"
echo "==================================="
