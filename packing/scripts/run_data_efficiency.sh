#!/usr/bin/env bash
# Data Efficiency Study (Experiment 3a-3d)
# Runs all 4 experiments sequentially. If one fails, logs the error and continues.

cd /home/sra/packsarm

DATASET=./packsarm/lerobot_dataset
PROGRESS=./packsarm/lerobot_dataset/sarm_progress.parquet
STEPS=50000
SAVE_FREQ=10000
LOG_FREQ=100
BATCH=32

COMMON_ARGS=(
  --policy.type=diffusion
  --dataset.repo_id="$DATASET"
  --dataset.root="$DATASET"
  --steps=$STEPS
  --eval_freq=0
  --save_freq=$SAVE_FREQ
  --log_freq=$LOG_FREQ
  --batch_size=$BATCH
  --policy.push_to_hub=false
  --wandb.enable=true
  --wandb.project=packsarm
  --wandb.entity=dimios45-sra-vjti
)

RABC_ARGS=(
  --use_rabc=true
  --rabc_progress_path="$PROGRESS"
  --rabc_head_mode=sparse
  --rabc_kappa=0.01
)

FAILED=()

run_experiment() {
  local name="$1"
  local outdir="$2"
  shift 2

  echo ""
  echo "=========================================="
  echo "$name"
  echo "=========================================="

  # Remove stale output dir from a previous failed attempt
  if [ -d "$outdir" ] && [ ! -f "$outdir/training_metrics.jsonl" ]; then
    echo "Removing stale output dir: $outdir"
    rm -rf "$outdir"
  fi

  # Skip only if fully completed (JSONL has all expected log entries)
  if [ -f "$outdir/training_metrics.jsonl" ]; then
    lines=$(wc -l < "$outdir/training_metrics.jsonl")
    expected=$(( STEPS / LOG_FREQ ))
    if [ "$lines" -ge "$expected" ]; then
      echo "Already completed ($lines entries), skipping. Delete $outdir to re-run."
      return 0
    else
      echo "Incomplete run ($lines/$expected entries). Removing and restarting."
      rm -rf "$outdir"
    fi
  fi

  python -m lerobot.scripts.lerobot_train \
    "${COMMON_ARGS[@]}" \
    --output_dir="$outdir" \
    "$@"

  if [ $? -ne 0 ]; then
    echo "FAILED: $name"
    FAILED+=("$name")
  fi
}

# 3a: RA-BC with 10 episodes
run_experiment "Experiment 3a: RA-BC with 10 episodes" \
  ./outputs/data_eff_rabc_10ep \
  "${RABC_ARGS[@]}" \
  --dataset.episodes="[0,1,2,3,4,5,6,7,8,9]" \
  --policy.repo_id=local/data_eff_rabc_10ep

# 3b: Vanilla BC with 10 episodes
run_experiment "Experiment 3b: Vanilla BC with 10 episodes" \
  ./outputs/data_eff_bc_10ep \
  --use_rabc=false \
  --dataset.episodes="[0,1,2,3,4,5,6,7,8,9]" \
  --policy.repo_id=local/data_eff_bc_10ep

# 3c: RA-BC with 25 episodes
run_experiment "Experiment 3c: RA-BC with 25 episodes" \
  ./outputs/data_eff_rabc_25ep \
  "${RABC_ARGS[@]}" \
  --dataset.episodes="[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24]" \
  --policy.repo_id=local/data_eff_rabc_25ep

# 3d: Vanilla BC with 25 episodes
run_experiment "Experiment 3d: Vanilla BC with 25 episodes" \
  ./outputs/data_eff_bc_25ep \
  --use_rabc=false \
  --dataset.episodes="[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24]" \
  --policy.repo_id=local/data_eff_bc_25ep

echo ""
echo "=========================================="
echo "All experiments attempted."
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "Status: ALL PASSED"
else
  echo "Status: ${#FAILED[@]} FAILED:"
  for f in "${FAILED[@]}"; do echo "  - $f"; done
fi
echo ""
echo "JSONL logs:"
for d in data_eff_rabc_10ep data_eff_bc_10ep data_eff_rabc_25ep data_eff_bc_25ep; do
  if [ -f "./outputs/$d/training_metrics.jsonl" ]; then
    lines=$(wc -l < "./outputs/$d/training_metrics.jsonl")
    echo "  outputs/$d/training_metrics.jsonl  ($lines entries)"
  else
    echo "  outputs/$d/training_metrics.jsonl  (MISSING)"
  fi
done
echo "=========================================="
