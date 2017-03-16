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

  eval ${this}_err=""
  eval ${this}_ret=""

  eval ${2}=$3
}

function GitHub_get()
{
  base=$(expr "$FUNCNAME" : '\([a-zA-Z][a-zA-Z0-9]*\)')
  this=$1

  eval ${this}_err=""
  eval ${this}_ret=""

  eval ${this}_ret=${!2}
}

function GitHub_login()
{
  base=$(expr "$FUNCNAME" : '\([a-zA-Z][a-zA-Z0-9]*\)')
  this=$1

  eval ${this}_err=""
  eval ${this}_ret=""

  # Check if a username has been set; if not attempt to detect, or request it
  if [ -z ${USERNAME+x} ]; then
    if [ -f "$HOME/.git-credentials" ]; then
      # Get the base domain from GITHUB_HOST
      uri_parser "$GITHUB_HOST" || {
	echo "ERR: Github host is not a valid uri: $GITHUB_HOST"
	_usage
      }
      eval _base_host=$uri_host

      # Find a matching set of credentials in ~/.git-credentials
      while read -r line; do
	uri_parser $line
	if [ $uri_host == $_base_host ]; then
          echo "Found ${use_use}@${_base_host} credentials in $HOME/.git-credentials."
          echo "Do you want to use these credentials? <Y>es or <N>o"
          read -s -n1 REPLY
          case $REPLY in
            y | Y)
              USERNAME=$uri_user
              PASSWORD=$uri_password
              break
              ;;
          esac
	fi
      done < "$HOME/.git-credentials"
    fi

    # Username still not found
    if [ -z ${USERNAME+x} ]; then
      read -ep "Enter the Github username: " USERNAME
    fi
  fi

  # Check if a password has been set; if not request it
  if [ -z ${PASSWORD+x} ]; then
    read -esp "Enter the GitHub password or access token for $USERNAME: " PASSWORD
    echo
  fi

  CURL_OPT="-s -u $USERNAME:$PASSWORD"

  # Perform a test login
  _test_login=$(curl $CURL_OPT $GITHUB_HOST)

  # Check if the account requires 2FA
  if [[ $_test_login == *"Must specify two-factor authentication"* ]]; then
    echo "ERR: Account requires 2FA, please create an access token."
    _usage
  fi

  if [[ $_test_login == *"Bad credentials"* ]]; then
    echo "ERR: Invalid username or password."
    _usage
  fi

  # Return the logged in users name on success
  eval ${this}_ret=$(curl $CURL_OPT $GITHUB_HOST/user | _jsonval login | xargs)
}



function _jsonval() {
  key=$1
  awk  -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$key'\042/){print $(i+1)}}}' | tr -d '"' | sed -n 1p
}

#####
## Helper functions
#####

# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
# from http://vpalos.com/537/uri-parsing-using-bash-built-in-features/
function uri_parser() {
  # uri capture
  uri="$@"

  # safe escaping
  uri="${uri//\`/%60}"
  uri="${uri//\"/%22}"

  # top level parsing
  pattern='^(([a-z]{3,5})://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
  [[ "$uri" =~ $pattern ]] || return 1;

  # component extraction
  uri=${BASH_REMATCH[0]}
  uri_schema=${BASH_REMATCH[2]}
  uri_address=${BASH_REMATCH[3]}
  uri_user=${BASH_REMATCH[5]}
  uri_password=${BASH_REMATCH[7]}
  uri_host=${BASH_REMATCH[8]}
  uri_port=${BASH_REMATCH[10]}
  uri_path=${BASH_REMATCH[11]}
  uri_query=${BASH_REMATCH[12]}
  uri_fragment=${BASH_REMATCH[13]}

  # path parsing
  count=0
  path="$uri_path"
  pattern='^/+([^/]+)'
  while [[ $path =~ $pattern ]]; do
    eval "uri_parts[$count]=\"${BASH_REMATCH[1]}\""
    path="${path:${#BASH_REMATCH[0]}}"
    let count++
  done

  # query parsing
  count=0
  query="$uri_query"
  pattern='^[?&]+([^= ]+)(=([^&]*))?'
  while [[ $query =~ $pattern ]]; do
    eval "uri_args[$count]=\"${BASH_REMATCH[1]}\""
    eval "uri_arg_${BASH_REMATCH[1]}=\"${BASH_REMATCH[3]}\""
    query="${query:${#BASH_REMATCH[0]}}"
    let count++
  done

  # return success
  return 0
}

# This is from https://github.com/dominictarr/JSON.sh
GREP=grep
EGREP=egrep

_json_tokenize() {
  local ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
  local CHAR='[^[:cntrl:]"\\]'
  local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
  local VARIABLE="\\\$[A-Za-z0-9_]*"
  local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'
  $EGREP -ao "$STRING|$VARIABLE|$NUMBER|$KEYWORD|$SPACE|." --color=never | $EGREP -v "^$SPACE$"  # eat whitespace
}

_json_parse_array() {
  local index=0
  local ary=''

  read -r Token

  case "$Token" in
    ']') ;;
    *)
      while :
      do
        _json_parse_value "$1" "`printf "%012d" $index`"

        (( index++ ))
        ary+="$Value"

        read -r Token
        case "$Token" in
          ']') break ;;
          ',') ary+=_ ;;
          *)
            echo "Array syntax malformed"
            break ;;
        esac
        read -r Token
      done
      ;;
  esac
}

_json_parse_object() {
  local key
  local obj=''
  read -r Token

  case "$Token" in
    '}') ;;
    *)
      while :
      do
        # The key, it should be valid
        case "$Token" in
          '"'*'"'|\$[A-Za-z0-9_]*) key=$Token ;;
          # If we get here then we aren't on a valid key
          *)
            echo "Object without a Key"
            break
            ;;
        esac

        # A colon
        read -r Token

        # The value
        read -r Token
        _json_parse_value "$1" "$key"
        obj+="$key:$Value"

        read -r Token
        case "$Token" in
          '}') break ;;
          ',') obj+=_ ;;
        esac
        read -r Token
      done
    ;;
  esac
}

_json_sanitize_value() {
  value=""
  IFS=
  while read -r -n 1 token; do
    case "$token" in
      [\-\\\"\;,=\(\)\[\]{}.\':\ ])
        value+=`printf "%d" \'$token`
        ;;
      *)
        value+="$token"
        ;;
    esac
  done
  echo $value
}

_json_parse_value() {
  local start=${1/%\"/}
  local end=${2/#\"/}

  local jpath="${start:+${start}_}$end"
  local prej=${jpath/#\"/}
  prej=${prej/%\"/}

  prej="`echo $prej | _json_sanitize_value`"
  [ "$prej" ] && prej="_$prej"

  case "$Token" in
    '{') _json_parse_object "$jpath" ;;
    '[') _json_parse_array  "$jpath" ;;

    *)
      Value=$Token
      Path="$Prefix$prej"
      Path=${Path/#_/}
      echo _data_${Path// /}=$Value
      ;;
  esac
}

_json_parse() {
  read -r Token
  _json_parse_value
  read -r Token
}
