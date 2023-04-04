#!/bin/bash

BINARY_PATH="./connect"

# Use double quotes to prevent word splitting and globbing
# Change to another env var, e.g. CONNECT_TYPE
while [ "$CONNECT" = "SFTP_NODE" ] && [ ! -e "./spend/$@"* ] && [ ! -e "./users/$@"* ]; do
  # Use "$@" to pass all command-line arguments as separate arguments to the binary
  $BINARY_PATH "$@"
  if [ $? -eq 0 ]; then
    echo "Binary ran successfully"
    break
  fi
  echo "Binary returned non-zero exit code, restarting..."
done
