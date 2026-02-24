#!/bin/bash
# Stage 2: Fine-tune from 10K checkpoint with low constant LR
#
# This continues training from the 10K checkpoint (which works!)
# with very low LR to fine-tune without overfitting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

# Stage 2 resumes from Stage 1's output directory (uses latest checkpoint = 010000)
OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc_20k_proper}"

RABC_PROGRESS="${HOME}/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

if [ ! -d "$OUTPUT_DIR/checkpoints/010000" ]; then
    echo "Error: Stage 1 checkpoint not found: $OUTPUT_DIR/checkpoints/010000"
    echo "Run Stage 1 first: ./train_dp_aloha_rabc_20k_proper.sh"
    exit 1
fi

echo "=================================================================="
echo "Stage 2: Fine-tuning 10K→20K (resuming from 010000 checkpoint)"
echo "=================================================================="
echo "Output dir: $OUTPUT_DIR"
echo "Resuming from: 010000 (lr=9e-09, already converged)"
echo "LR during stage 2: stays at cosine minimum (~1e-8)"
echo "Steps:      10K → 20K (saves at 12K, 14K, 16K, 18K, 20K)"
echo "=================================================================="
echo ""

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
    --save_freq=2000 \
    --log_freq=100 \
    --config_path="${OUTPUT_DIR}/checkpoints/010000/pretrained_model/train_config.json" \
    --resume=true \
    --output_dir="${OUTPUT_DIR}" \
    --policy.repo_id=local/dp_aloha_rabc_20k_proper \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo ""
echo "=================================================================="
echo "✓ Stage 2 Complete!"
echo "=================================================================="
echo "Checkpoints saved in $OUTPUT_DIR/checkpoints/:"
echo "  - 012000 (+2K fine-tuning)"
echo "  - 014000 (+4K fine-tuning)"
echo "  - 016000 (+6K fine-tuning)"
echo "  - 018000 (+8K fine-tuning)"
echo "  - 020000 (+10K fine-tuning, final)"
echo "=================================================================="
