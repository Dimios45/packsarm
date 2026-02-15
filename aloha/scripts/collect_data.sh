#!/bin/bash
# Collect demonstration data from RoboTwin simulation
# Usage: ./collect_data.sh [num_episodes] [output_dir]
#
# IMPORTANT: Activate robotwin-env before running this script:
#   source /home/sra/packsarm/robotwin-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
ROBOTWIN_DIR="${SCRIPT_DIR}/../../WBCD-Packing-RoboTwin"

NUM_EPISODES="${1:-50}"
OUTPUT_DIR="${2:-${PROJECT_DIR}/data/packing/wbcd}"

echo "==================================="
echo "Collecting Packing Demonstrations"
echo "Episodes:  $NUM_EPISODES"
echo "Output:    $OUTPUT_DIR"
echo "==================================="

if [ ! -d "$ROBOTWIN_DIR" ]; then
    echo "Error: WBCD-Packing-RoboTwin not found at $ROBOTWIN_DIR"
    echo "Please clone: git clone https://github.com/BabyBirthday/WBCD-Packing-RoboTwin.git"
    exit 1
fi

cd "$ROBOTWIN_DIR"

python collect_data.py \
    --task packing \
    --num_episodes "$NUM_EPISODES" \
    --output_dir "$OUTPUT_DIR"

echo "==================================="
echo "Data Collection Complete!"
echo "Episodes saved to: $OUTPUT_DIR"
echo "==================================="
