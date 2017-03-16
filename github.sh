#!/usr/bin/env bash
## A Bash GitHub API Library
##
## Usage:
##
## #!/usr/bin/env bash
##
## . git-bash-lib.sh
## 
## function main()
## {
##   GitHub 'github'
##
##   $github_login 'username' 'password'
##   $github_stuff
## }
##
## main


## Class Constructor
##
## Create a new instance of the GitHub class using <name>. Set configuration
## options via additional options.
##
## Accepted options:
##   -u|--username <username> The GitHub username to use
##   -p|--password <password> The GitHub password to use
##   -h|--host <url>          The GitHub URL (for GHE instances)
##
## Github <name> [options]
##
function GitHub()
{
  # Defaults
  USERNAME=$(git config user.email)
  GITHUB_HOST="https://github.com/"
  
  # Instanciation
  base=$FUNCNAME
  this=$1

  # Instance management of error and return values
  export ${this}_err=""
  export ${this}_ret=""

  # Parse constructor options
  shift # skip instance name
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -u|--username)
	USERNAME="$2"
	shift
	;;
      -p|--password)
	PASSWORD="$2"
	shift
	;;
      -h|--host)
	GITHUB_HOST=${2%/}
	shift
	;;
    esac
    shift
  done

  # Export methods to instance
  for method in $(compgen -A function)
  do
    export ${method/#$base\_/$this\_}="${method} ${this}"
  done
}

function GitHub_set()
{
  base=$(expr "$FUNCNAME" : '\([a-zA-Z][a-zA-Z0-9]*\)')
  this=$1
#  ${this}_err=""; ${this}_ret="";

  eval ${2}=$3
}

function GitHub_get()
{
  base=$(expr "$FUNCNAME" : '\([a-zA-Z][a-zA-Z0-9]*\)')
  this=$1

  eval ${this}_ret=${!2}
}

function GitHub_blah()
{
  base=$(expr "$FUNCNAME" : '\([a-zA-Z][a-zA-Z0-9]*\)')
  this=$1
}



function _jsonval() {
  key=$1
  awk  -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$key'\042/){print $(i+1)}}}' | tr -d '"' | sed -n 1p
}

