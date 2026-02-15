#!/bin/bash
# Convert RoboTwin HDF5 data to LeRobot v3.0 dataset format
# Usage: ./convert_data.sh [input_dir] [output_dir]
#
# IMPORTANT: Activate sarm-env before running this script:
#   source /home/sra/packsarm/sarm-env/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
LEROBOT_DIR="${SCRIPT_DIR}/../../lerobot"

INPUT_DIR="${1:-${PROJECT_DIR}/data/packing/wbcd}"
OUTPUT_DIR="${2:-${PROJECT_DIR}/lerobot_dataset}"

echo "==================================="
echo "Converting Data to LeRobot Format"
echo "Input:   $INPUT_DIR"
echo "Output:  $OUTPUT_DIR"
echo "==================================="

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input data not found at $INPUT_DIR"
    echo "Please run collect_data.sh first"
    exit 1
fi

# Add lerobot to path
export PYTHONPATH="${LEROBOT_DIR}/src:${PYTHONPATH}"

python "${PROJECT_DIR}/data/convert_robotwin_to_lerobot.py" \
    --input-dir "$INPUT_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --fps 15 \
    --robot-type bimanual_arx5 \
    --task "Pack the object into the box"

echo "==================================="
echo "Conversion Complete!"
echo "LeRobot dataset saved to: $OUTPUT_DIR"
echo "==================================="
