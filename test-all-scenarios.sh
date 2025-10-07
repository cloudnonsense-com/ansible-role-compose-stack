#!/usr/bin/env bash
set -euo pipefail

# Start timing
START_TIME=$(date +%s)

# Activate virtual environment
source ~/.venv_cnns/bin/activate

# Get molecule command from first parameter, default to 'test'
MOLECULE_CMD="${1:-test}"

# Get all scenario directories except 'shared' and 'group_vars'
scenarios=$(find molecule -mindepth 1 -maxdepth 1 -type d ! -name 'shared' ! -name 'group_vars' -exec basename {} \;)

echo "Found scenarios: $scenarios"
echo "Running molecule command: $MOLECULE_CMD"
echo ""

# Run molecule command for each scenario
FAILED=0
for scenario in $scenarios; do
  echo "=========================================="
  echo "Running 'molecule $MOLECULE_CMD' for scenario: $scenario"
  echo "=========================================="
  if ! molecule "$MOLECULE_CMD" -s "$scenario"; then
    FAILED=1
    break
  fi
  echo ""
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo ""

if [ $FAILED -eq 0 ]; then
  cat <<'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗       ║
║   ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝       ║
║   ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗       ║
║   ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║       ║
║   ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║       ║
║   ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝       ║
║                                                                   ║
║          All scenario tests completed successfully! ✓             ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
  echo "Total execution time: ${MINUTES}m ${SECONDS}s"
  exit 0
else
  cat <<'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ███████╗ █████╗ ██╗██╗     ███████╗██████╗                      ║
║   ██╔════╝██╔══██╗██║██║     ██╔════╝██╔══██╗                     ║
║   █████╗  ███████║██║██║     █████╗  ██║  ██║                     ║
║   ██╔══╝  ██╔══██║██║██║     ██╔══╝  ██║  ██║                     ║
║   ██║     ██║  ██║██║███████╗███████╗██████╔╝                     ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝                      ║
║                                                                   ║
║              One or more scenario tests failed! ✗                 ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
  echo "Total execution time: ${MINUTES}m ${SECONDS}s"
  exit 1
fi
