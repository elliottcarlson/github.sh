#!/usr/bin/env bash

. github.sh

function main()
{
  GitHub 'github' -h https://git.generalassemb.ly/api/v3/
  echo $GITHUB_HOST
  $github_get GITHUB_HOST
  echo "Connecting to $github_ret..."

  $github_login
  if [ $? -eq 0 ]; then
    USER=$github_ret
    echo "Logged in as $USER..."
  else
    echo "ERR: $github_err"
    exit
  fi
}

main
