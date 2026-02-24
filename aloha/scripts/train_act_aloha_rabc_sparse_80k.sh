#!/bin/bash
# Train ACT with RA-BC — Paper-accurate config
#
# Key paper settings (arxiv.org/html/2509.25358):
#   - Two-scheme SARM uses SPARSE head for RA-BC (not dense, not averaged)
#   - kappa = 0.01 (top ~5% threshold, paper-specified)
#   - chunk_size Δ = 25 (paper Sec 4.2: aligned with policy action chunking)
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/act_aloha_rabc_sparse_20k}"
NUM_STEPS="${2:-20000}"

RABC_PROGRESS="/home/sra/.cache/huggingface/lerobot/lerobot/aloha_sim_transfer_cube_human/sarm_progress.parquet"

if [ ! -f "$RABC_PROGRESS" ]; then
    echo "Error: RA-BC progress file not found: $RABC_PROGRESS"
    exit 1
fi

echo "==================================================================="
echo "Training ACT with RA-BC — Paper-accurate config"
echo "==================================================================="
echo "Dataset:    lerobot/aloha_sim_transfer_cube_human"
echo "Output:     $OUTPUT_DIR"
echo "Steps:      $NUM_STEPS"
echo "head_mode:  sparse (two-scheme SARM evaluated in sparse mode)"
echo "kappa:      0.01   (paper-specified, ~top 5% threshold)"
echo "chunk_size: 25     (Δ=25, paper Sec 4.2)"
echo "==================================================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=act \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --use_rabc=true \
    --rabc_progress_path="$RABC_PROGRESS" \
    --rabc_head_mode=sparse \
    --rabc_chunk_size=25 \
    --rabc_kappa=0.01 \
    --rabc_epsilon=1e-6 \
    --batch_size=8 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=5000 \
    --log_freq=100 \
    --output_dir="$OUTPUT_DIR" \
    --policy.repo_id=local/act_aloha_rabc_sparse_20k \
    --policy.push_to_hub=false \
    --wandb.enable=false

echo "==================================================================="
echo "Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================================================="
echo ""
echo "Evaluate with:"
echo "  ./aloha/scripts/eval_act_aloha.sh $OUTPUT_DIR/checkpoints/last/pretrained_model 50 act_rabc_sparse_80k"
