#!/usr/bin/env bash
set -euo pipefail

# Start timing
START_TIME=$(date +%s)

# Activate virtual environment
source ~/.venv_cnns/bin/activate

# Get molecule command from first parameter, default to 'test'
MOLECULE_CMD="${1:-test}"

# Get all scenario directories except 'default'
scenarios=$(find molecule -mindepth 1 -maxdepth 1 -type d ! -name 'default' -exec basename {} \;)

echo "Found scenarios: $scenarios"
echo "Running molecule command: $MOLECULE_CMD"
echo ""

# Run molecule command for each scenario
for scenario in $scenarios; do
  echo "=========================================="
  echo "Running 'molecule $MOLECULE_CMD' for scenario: $scenario"
  echo "=========================================="
  molecule "$MOLECULE_CMD" -s "$scenario"
  echo ""
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "All scenario '$MOLECULE_CMD' commands completed successfully!"
echo "Total execution time: ${MINUTES}m ${SECONDS}s"
