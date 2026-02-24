#!/bin/bash
# Train RA-BC DiffusionPolicy for 20K steps with PROPER fast LR decay
#
# Strategy:
#  Stage 1 (0-10K): Fast LR decay (1e-4 → 1e-8) - builds working model
#  Stage 2 (10K-20K): Continue at very low LR (1e-8) - fine-tuning without overfitting
#
# Saves checkpoints every 2K from 10K-20K: 10K, 12K, 14K, 16K, 18K, 20K

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc_20k_proper}"
RABC_PROGRESS="${HOME}/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: RA-BC progress file not found: $RABC_PROGRESS"
    exit 1
fi

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

echo "=================================================================="
echo "Training RA-BC DiffusionPolicy - 20K steps with PROPER LR schedule"
echo "=================================================================="
echo "Dataset:  lerobot/aloha_sim_transfer_cube_human"
echo "Output:   $OUTPUT_DIR"
echo ""
echo "Stage 1 (0-10K):   Fast LR decay (matches successful 10K run)"
echo "Stage 2 (10K-20K): Low LR fine-tuning (prevents overfitting)"
echo ""
echo "Checkpoints: 10K, 12K, 14K, 16K, 18K, 20K"
echo "=================================================================="
echo ""

# Stage 1: Train 0-10K with fast LR decay (like successful 10K run)
echo "▶ STAGE 1: Training steps 0-10K with fast LR decay..."
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
    --steps=10000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_rabc_20k_proper \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo ""
echo "✓ Stage 1 complete! Checkpoint saved at 10K steps"
echo ""

# Stage 2: Load 10K checkpoint, train for another 10K with very low fixed LR
echo "▶ STAGE 2: Fine-tuning from 10K checkpoint with low LR..."
echo "  (LR = 1e-8 constant, matching Stage 1 final LR)"
echo ""
echo "Note: Run Stage 2 separately with:"
echo "  ./aloha/scripts/train_dp_aloha_rabc_stage2.sh"
echo ""
echo "Or run now with corrected arguments..."
echo ""

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
    --steps=10000 \
    --eval_freq=0 \
    --save_freq=2000 \
    --log_freq=100 \
    --checkpoint_path="${OUTPUT_DIR}/checkpoints/010000" \
    --optimizer.lr=1e-8 \
    --scheduler.name=constant \
    --output_dir="${OUTPUT_DIR}_stage2" \
    --policy.repo_id=local/dp_aloha_rabc_20k_proper_stage2 \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo ""
echo "=================================================================="
echo "✓ Training Complete!"
echo "=================================================================="
echo "Checkpoints saved:"
echo "  - 010000 (Stage 1 end, LR fully decayed)"
echo "  - 012000 (Fine-tuning +2K)"
echo "  - 014000 (Fine-tuning +4K)"
echo "  - 016000 (Fine-tuning +6K)"
echo "  - 018000 (Fine-tuning +8K)"
echo "  - 020000 (Fine-tuning +10K, final)"
echo ""
echo "Expected performance:"
echo "  - 10K checkpoint: ~12-24% (matches successful run)"
echo "  - 12K-20K: Similar or better (fine-tuning without overfitting)"
echo "=================================================================="
