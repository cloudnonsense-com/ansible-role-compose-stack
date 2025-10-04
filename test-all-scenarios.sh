#!/usr/bin/env bash
set -euo pipefail

# Activate virtual environment
source ~/.venv_cnns/bin/activate

# Get all scenario directories except 'default'
scenarios=$(find molecule -mindepth 1 -maxdepth 1 -type d ! -name 'default' -exec basename {} \;)

echo "Found scenarios: $scenarios"
echo ""

# Run molecule test for each scenario
for scenario in $scenarios; do
  echo "=========================================="
  echo "Testing scenario: $scenario"
  echo "=========================================="
  molecule test -s "$scenario"
  echo ""
done

echo "All scenario tests completed successfully!"
