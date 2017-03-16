#!/usr/bin/env bash

. git-bash-lib.sh

function main()
{
  GitHub 'github' -h https://git.generalassemb.ly
  echo $base


  echo "---"

  $github_get GITHUB_HOST
  echo $github_ret

  $github_blah 'woot'


  $github_set GITHUB_HOST https://www.github.com

  $github_get GITHUB_HOST
  echo $github_ret

}

main
