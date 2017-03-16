#!/usr/bin/env bash

cd "${0%/*}"

if hash bats 2>/dev/null; then
  bats test.bats
else
  echo "Error; test require bats to be installed."
  echo "See: https://github.com/sstephenson/bats"
fi
