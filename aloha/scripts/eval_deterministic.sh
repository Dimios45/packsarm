#!/bin/bash
# Deterministic evaluation with fixed seeds for reproducibility
#
# This script runs evaluation with specific seeds to ensure
# consistent results across multiple runs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

CHECKPOINT_PATH="${1}"
N_EPISODES="${2:-50}"
OUTPUT_NAME="${3:-eval_deterministic}"
SEED="${4:-1000}"

if [ -z "$CHECKPOINT_PATH" ]; then
    echo "Usage: $0 <checkpoint_path> [n_episodes] [output_name] [seed]"
    echo ""
    echo "Examples:"
    echo "  $0 outputs/model/checkpoints/last/pretrained_model 50 my_eval 1000"
    exit 1
fi

# Convert to absolute path if relative
if [[ ! "$CHECKPOINT_PATH" = /* ]]; then
    CHECKPOINT_PATH="${SCRIPT_DIR}/../${CHECKPOINT_PATH}"
fi

if [ ! -d "$CHECKPOINT_PATH" ]; then
    echo "Error: Checkpoint path does not exist: $CHECKPOINT_PATH"
    exit 1
fi

OUTPUT_DIR="${SCRIPT_DIR}/../outputs/${OUTPUT_NAME}"

echo "==================================="
echo "Deterministic Evaluation"
echo "Checkpoint: $CHECKPOINT_PATH"
echo "Episodes:   $N_EPISODES"
echo "Seed:       $SEED (FIXED for reproducibility)"
echo "Output:     $OUTPUT_DIR"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_eval \
    --policy.path="$CHECKPOINT_PATH" \
    --env.type=aloha \
    --env.task=AlohaTransferCube-v0 \
    --eval.batch_size=1 \
    --eval.n_episodes="$N_EPISODES" \
    --policy.use_amp=false \
    --policy.device=cuda \
    --seed="$SEED" \
    --output_dir="$OUTPUT_DIR"

echo "==================================="
echo "Deterministic Evaluation Complete!"
echo "Results saved to: $OUTPUT_DIR"
echo ""
echo "To verify reproducibility, run again:"
echo "  $0 $CHECKPOINT_PATH $N_EPISODES ${OUTPUT_NAME}_verify $SEED"
echo "==================================="
