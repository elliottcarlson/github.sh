#!/usr/bin/env bats

. ../github.sh

GitHub "github"

@test "creates instance" {
  [ $base == GitHub ]
}

@test "exports instance methods" {
  [ -n "${github_get+1}" ]
  [ -n "${github_set+1}" ]
  [ -n "${github_blah+1}" ]
}

@test "_jsonval helper test" {
  json='{"response":{"code":"200","message":"OK"},"item":"https://someurl.com/api/"}'
  code=$(echo ${json} | _jsonval code)
  message=$(echo ${json} | _jsonval message)
  item=$(echo ${json} | _jsonval item)
  [ $code == "200" ]
  [ $message == "OK" ]
  [ $item == "https" ] # Known issue, TODO
}
