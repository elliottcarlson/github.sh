#!/usr/bin/env bash

. github.sh

function main()
{
  GitHub 'github' -h https://git.generalassemb.ly

  $github_get GITHUB_HOST
  echo "Connecting to $github_ret"

  $github_login
  echo $github_ret


}

main
