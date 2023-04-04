#!/bin/bash

BINARY_PATH=./connect

echo $SFTP_HOST
echo $SFTP_USERNAME
echo $SFTP_PASSWORD

# Run the binary in a loop until it returns a successful exit code
# change to another env var
while [ $CONNECT = "SFTP_NODE" ]; do
  $BINARY_PATH "$@"
  if [ $? -eq 0 ]; then
    echo "Binary ran successfully"
    break
  fi
  echo "Binary returned non-zero exit code, restarting..."
done

