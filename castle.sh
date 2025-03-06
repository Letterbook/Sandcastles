#!/bin/sh -e

# shellcheck disable=SC3024
# shellcheck disable=SC3030
# shellcheck disable=SC1078                                                  #
HELP="""Sandcastles - federation sandbox

Easily and quickly set up a federation sandbox, for testing against
production-like configurations of multiple fediverse backends.
"""
USAGE="Usage: ${CMD:=${0##*/}} [init|up|down|build|help] [APPS...|(-a|--all)] [-h|--help]"
DIR=$(dirname "$(readlink -f -- "$0")")

exit2 () { printf >&2 "%s:  %s: '%s'\n%s\n" "$CMD" "$1" "$2" "$USAGE"; exit 2; }
exit_runtime () { 
  printf >&2 "Sandcastles require a container runtime\nYou must install either podman (and podman-compose) or docker"; 
  exit 3; 
}
exit_usage() { printf "%s\n" "$USAGE"; exit 0; }
exit_help() { printf "%s\n%s\n" "$HELP" "$USAGE"; exit 0; }
check () { { [ "$1" != "$EOL" ] && [ "$1" != '--' ]; } || exit2 "missing argument" "$2"; }  # avoid infinite loop

# parse action
case "$1" in
  # handle help cases
  -h | --help | help ) exit_help;;
  '' ) exit_usage;;
  init ) opt_action=$1; shift
    HELP="""${opt_action} - perform first time setup
    
    Prepare the project to run in your environment. Initializes a private
    certificate authority, to provide ssl certificates to the sandcastle apps
    """
    USAGE="Usage: ${CMD:=${0##*/}} ${opt_action} [-h|--help]"
    ;; 
  up ) opt_action=$1; shift
    HELP="""${opt_action} - run selected apps
    
    Run the specified apps, or all apps with the --all flag
    """
    USAGE="Usage: ${CMD:=${0##*/}} ${opt_action} [APPS...|(-a|--all)] [-h|--help]"
    ;;
  down ) opt_action=$1; shift
    HELP="""${opt_action} - shut down the selected apps
    
    Shut down the specified apps, or all apps with the --all flag
    """
    USAGE="Usage: ${CMD:=${0##*/}} ${opt_action} [APPS...|(-a|--all)] [-h|--help]"
    ;;
  build ) opt_action=$1; shift
    HELP="""${opt_action} - build the required images
    
    Build container images with trust for your private CA
    """
    USAGE="Usage: ${CMD:=${0##*/}} ${opt_action} [APPS...|(-a|--all)] [-h|--help]"
    ;;
  * ) exit2 "invalid command" "$opt_action";;
esac

# parse remaining command-line options
set -- "$@" "${EOL:=$(printf '\1\3\3\7')}"  # end-of-list marker
opt_apps=()
while [ "$1" != "$EOL" ]; do
  opt="$1"; shift
  case "$opt" in

    # defined options - EDIT HERE!
    -a | --all  ) opt_all=true;;
    -h | --help ) exit_help;;

    # process special cases
    --) while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done;;   # parse remaining as passthrough
    --[!=]*=*) set -- "${opt%%=*}" "${opt#*=}" "$@";;                  # "--opt=arg"  ->  "--opt" "arg"
    -[A-Za-z0-9] | -*[!A-Za-z0-9]*) exit2 "invalid option" "$opt";;    # anything invalid like '-*'
    -?*) other="${opt#-?}"; set -- "${opt%$other}" "-${other}" "$@";;  # "-abc"  ->  "-a" "-bc"
    *) opt_apps+=("$opt");;                                            # positional, rotate to the end
  esac
done; shift

if (command -v podman >/dev/null 2>&1) && (command -v podman-compose >/dev/null 2>&1);  then
  env_runtime="podman"
elif command -v docker >/dev/null 2>&1;  then
  env_runtime="docker"
else
  exit_runtime
fi

# example of script using command-line options
printf "%s" """DIR = '$DIR'
action = '$opt_action'
@ = ($*)
apps = ${opt_apps[*]}
all = '$opt_all'
runtime = '$env_runtime'
"""

case $opt_action in
  up)
    cmd_files=()
    if $opt_all; then
      all_files=$(find "$DIR" -type f -name "*.compose.yml")
      # shellcheck disable=SC2048
      for n in ${all_files[*]}; do cmd_files+=("-f" "$n"); done 
    else
      # shellcheck disable=SC2048
      for n in ${opt_apps[*]}; do cmd_files+=("-f" "$n.compose.yml"); done
    fi
    echo "$env_runtime" "compose" "${cmd_files[@]}" "up" "-d"
#    exec "$env_runtime" "compose" "${cmd_files[@]}" "up" "-d"
  ;;
esac
