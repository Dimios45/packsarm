#!/bin/bash
# Run the complete PackSARM pipeline
# Usage: ./run_pipeline.sh [stage]
#   stage: all, collect, convert, sarm, rabc, policy (default: all)
#
# IMPORTANT: Activate sarm-env before running this script:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."

STAGE="${1:-all}"

echo "========================================="
echo "PackSARM Pipeline"
echo "Stage: $STAGE"
echo "========================================="

run_collect() {
    echo ""
    echo ">>> Stage 1: Collect Demonstrations"
    echo "========================================='"
    # Note: requires robotwin-env, not sarm-env
    "${SCRIPT_DIR}/collect_data.sh"
}

run_convert() {
    echo ""
    echo ">>> Stage 2: Convert to LeRobot Format"
    echo "========================================="
    "${SCRIPT_DIR}/convert_data.sh"
}

run_sarm() {
    echo ""
    echo ">>> Stage 3: Train SARM Reward Model"
    echo "========================================="
    "${SCRIPT_DIR}/train_sarm.sh"
}

run_rabc() {
    echo ""
    echo ">>> Stage 4: Compute RA-BC Weights"
    echo "========================================="
    "${SCRIPT_DIR}/compute_rabc_weights.sh" \
        "${PROJECT_DIR}/outputs/sarm_wbcd_packing" \
        "${PROJECT_DIR}/lerobot_dataset"
}

run_policy() {
    echo ""
    echo ">>> Stage 5: Train Policy with RA-BC"
    echo "========================================="
    "${SCRIPT_DIR}/train_policy_rabc.sh" \
        "${PROJECT_DIR}/lerobot_dataset" \
        "${PROJECT_DIR}/outputs/policy_rabc"
}

case "$STAGE" in
    all)
        run_collect
        run_convert
        run_sarm
        run_rabc
        run_policy
        ;;
    collect)  run_collect ;;
    convert)  run_convert ;;
    sarm)     run_sarm ;;
    rabc)     run_rabc ;;
    policy)   run_policy ;;
    *)
        echo "Unknown stage: $STAGE"
        echo "Usage: $0 [all|collect|convert|sarm|rabc|policy]"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "Pipeline Complete!"
echo "========================================="
