#!/bin/bash

set -e

# Validate required environment variables
if [ -z "$GITHUB_ORGANIZATION" ]; then
    echo "Error: GITHUB_ORGANIZATION environment variable is required"
    exit 1
fi

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
    echo "Error: GITHUB_ACCESS_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$RUNNER_NAME" ]; then
    echo "Error: RUNNER_NAME environment variable is required"
    exit 1
fi

# Default values
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,Linux,X64"}

echo "Starting GitHub Actions Runner setup..."
echo "Organization: $GITHUB_ORGANIZATION"
echo "Runner Name: $RUNNER_NAME"
echo "Runner Labels: $RUNNER_LABELS"

# Cleanup function to deregister runner
cleanup() {
    echo "Caught signal, deregistering runner..."

    # Get removal token from GitHub API
    REMOVAL_TOKEN=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/orgs/$GITHUB_ORGANIZATION/actions/runners/remove-token" | jq -r '.token')

    if [ -n "$REMOVAL_TOKEN" ] && [ "$REMOVAL_TOKEN" != "null" ]; then
        # Remove the runner from GitHub Actions
        ./config.sh remove --token "$REMOVAL_TOKEN" || true
        echo "Runner deregistered successfully"
    else
        echo "Warning: Failed to get removal token, runner may remain registered"
    fi

    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT SIGQUIT SIGHUP

# Get registration token
echo "Getting registration token..."
REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/$GITHUB_ORGANIZATION/actions/runners/registration-token" | jq -r '.token')

if [ -z "$REGISTRATION_TOKEN" ] || [ "$REGISTRATION_TOKEN" = "null" ]; then
    echo "Error: Failed to get registration token. Check your access token and organization name."
    exit 1
fi

# Configure the runner
echo "Configuring runner..."
./config.sh \
    --url "https://github.com/$GITHUB_ORGANIZATION" \
    --token "$REGISTRATION_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --unattended \
    --replace

echo "Starting runner..."
# Run the runner in the background so we can handle signals
./run.sh &

# Wait for the runner process
wait $!
