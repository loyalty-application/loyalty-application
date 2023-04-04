#!/bin/bash

BINARY_PATH=./connect

# Run the binary in a loop until it returns a successful exit code
# change to another env var
while [ $(hostname) = "connect" ]; do
  $BINARY_PATH "$@"
  if [ $? -eq 0 ]; then
    echo "Binary ran successfully"
    break
  fi
  echo "Binary returned non-zero exit code, restarting..."
done
