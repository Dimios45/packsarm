#!/bin/bash
# Evaluate DiffusionPolicy on ALOHA transfer cube sim (NO CROP)
#
# Tests option 3: Disable cropping at eval time to fix vision grounding
#
# Usage:
#   ./eval_dp_aloha_nocrop.sh <checkpoint_path> [n_episodes] [output_name]
#
# Examples:
#   ./eval_dp_aloha_nocrop.sh outputs/dp_aloha_rabc/checkpoints/last/pretrained_model 10 rabc_50k_nocrop

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

CHECKPOINT_PATH="${1}"
N_EPISODES="${2:-10}"
OUTPUT_NAME="${3:-eval_nocrop}"

if [ -z "$CHECKPOINT_PATH" ]; then
    echo "Usage: $0 <checkpoint_path> [n_episodes] [output_name]"
    echo ""
    echo "Examples:"
    echo "  $0 outputs/dp_aloha_rabc/checkpoints/last/pretrained_model 10 rabc_50k_nocrop"
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

OUTPUT_DIR="${SCRIPT_DIR}/../outputs/eval_${OUTPUT_NAME}"

echo "==================================="
echo "Evaluating DiffusionPolicy (NO CROP)"
echo "Checkpoint: $CHECKPOINT_PATH"
echo "Episodes:   $N_EPISODES"
echo "Output:     $OUTPUT_DIR"
echo "Fix:        Disabled center crop at eval time"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_eval \
    --policy.path="$CHECKPOINT_PATH" \
    --policy.crop_shape=null \
    --env.type=aloha \
    --env.task=AlohaTransferCube-v0 \
    --eval.batch_size=1 \
    --eval.n_episodes="$N_EPISODES" \
    --policy.use_amp=false \
    --policy.device=cuda \
    --output_dir="$OUTPUT_DIR"

echo "==================================="
echo "Evaluation Complete!"
echo "Results saved to: $OUTPUT_DIR"
echo "==================================="
