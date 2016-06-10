#!/usr/bin/env bash
#
#####
# Describe your script here
#
#####

# exit on commands that error, unset variables, commands in pipe chains that
# fail
set -euo pipefail

# trap ctrl-c and call ctrl_c()
ctrl_c()
{
  echo -e "\n\e[1;31mcaught CTRL-C - EXITING!\e[0m"
  exit 1
}

trap ctrl_c SIGINT

# set some colours for use in the script
if tput setaf 1 &> /dev/null; then
  tput sgr0;
  bold=$(tput bold);
  reset=$(tput sgr0);
  red=$(tput setaf 160);
  green=$(tput setaf 64);
else
  bold='';
  reset="\e[0m";
  red="\e[1;31m";
  green="\e[1;32m";
fi

# add some outputting functions to print status, show errors, draw attention to
# output and exit on errors
# TODO: use the centos/debian logging functions libraries:-
# /lib/lsb/init-functions or /etc/init.d/functions

print_status()
{
  echo
  echo -e "[INFO] $1"
  echo
}

exit_on_error()
{
  echo -e "${red}${bold}[ERROR] Failure executing:${reset} $1"
  exit 1
}

run_command_noexit()
{
  echo -e "[INFO] Executing: ${1}..."
  bash -c "$1"
}

run_command()
{
  if [[ run_command_noexit "$1" ]]; then
    echo -e "${green}[OK]${reset}"
  else
    exit_on_error "$1"
  fi
}

main()
{
true # replace "true" with your functions in here
}

main "$@"
