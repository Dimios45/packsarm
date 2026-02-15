#!/bin/bash
# Train SARM (Stage-Aware Reward Model) on ALOHA transfer cube dataset
#
# Paper: "SARM: Stage-Aware Reward Modeling for Long Horizon Robot Manipulation"
# https://arxiv.org/abs/2509.25358
#
# Uses dense_only mode with VLM-annotated subtasks:
#   - Move right arm toward the cube
#   - Grasp the cube with right gripper
#   - Lift cube and move toward left arm
#   - Transfer cube to left gripper and release
#   - Retract both arms
#
# Temporal proportions auto-loaded from dataset meta/temporal_proportions_dense.json
#
# IMPORTANT: Activate sarm-env before running:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

OUTPUT_DIR="${1:-${SCRIPT_DIR}/../outputs/sarm_aloha_transfer_cube}"

# Dataset: 50 episodes, 400 frames each, 50 FPS, 14D state
# 2 epochs = 2 * 20000 / 64 = 625 steps
NUM_STEPS="${2:-625}"

echo "==================================="
echo "Training SARM on ALOHA Transfer Cube"
echo "Output:   $OUTPUT_DIR"
echo "Steps:    $NUM_STEPS (2 epochs)"
echo "==================================="

export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python -m lerobot.scripts.lerobot_train \
    --policy.type=sarm \
    --policy.annotation_mode=dense_only \
    --policy.n_obs_steps=8 \
    --policy.frame_gap=30 \
    --policy.max_rewind_steps=4 \
    --policy.hidden_dim=768 \
    --policy.num_heads=12 \
    --policy.num_layers=8 \
    --policy.image_key=observation.images.top \
    --policy.state_key=observation.state \
    --dataset.repo_id=lerobot/aloha_sim_transfer_cube_human \
    --batch_size=64 \
    --steps="$NUM_STEPS" \
    --eval_freq=0 \
    --save_freq=200 \
    --log_freq=50 \
    --output_dir="$OUTPUT_DIR" \
    --policy.push_to_hub=false \
    --policy.repo_id=local/sarm_aloha_transfer_cube \
    --wandb.enable=false

echo "==================================="
echo "SARM Training Complete!"
echo "Checkpoints saved to: $OUTPUT_DIR"
echo "==================================="
