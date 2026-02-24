#!/bin/bash
# Train RA-BC DiffusionPolicy — Paper-accurate config
#
# Key paper settings:
#   - Two-scheme SARM uses SPARSE head for RA-BC (not averaging)
#   - kappa = 0.01 (top ~5% threshold, paper-specified)
#   - chunk_size Δ = 25 (aligned with policy action chunking, paper Sec 4.2)
#   - Two-stage LR: Stage1 cosine 1e-4→1e-8 over 10K, Stage2 resume constant LR
#
# Reference: arxiv.org/html/2509.25358

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/dp_aloha_rabc_sparse_10k}"
RABC_PROGRESS="${HOME}/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: RA-BC progress file not found: $RABC_PROGRESS"
    exit 1
fi

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

echo "=================================================================="
echo "Training RA-BC DiffusionPolicy — Paper-accurate config"
echo "=================================================================="
echo "head_mode:  sparse (two-scheme SARM evaluated in sparse mode)"
echo "kappa:      0.01   (paper-specified, ~top 5% threshold)"
echo "chunk_size: 25     (Δ=25, aligned with policy action chunking)"
echo "LR:         cosine 1e-4 → 1e-8 over 10K steps (best convergence)"
echo "=================================================================="

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
    --rabc_head_mode=sparse \
    --rabc_chunk_size=25 \
    --rabc_kappa=0.01 \
    --rabc_epsilon=1e-6 \
    --batch_size=64 \
    --steps=10000 \
    --eval_freq=0 \
    --save_freq=10000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/dp_aloha_rabc_sparse_10k \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo ""
echo "=================================================================="
echo "Training Complete! Checkpoint at: $OUTPUT_DIR/checkpoints/010000"
echo "=================================================================="
echo ""
echo "Evaluate with:"
echo "  ./aloha/scripts/eval_dp_aloha.sh $OUTPUT_DIR/checkpoints/last/pretrained_model 50 dp_rabc_sparse_10k"
