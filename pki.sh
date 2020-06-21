#!/bin/bash

STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@"; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
INTERNAL() { read line cmd name < <(caller ${1:-0}); OOPS internal error in "$name" line "$line" function "$cmd"; }

usage()
{
  {
  printf 'Usage: %q command [args..]\n' "${0##*/}"
  printf '\tEasy to use wrapper to OpenSSL\n'
  printf '\tUse command "help" to list all commands\n'
  } >&2
  exit 42
}

args()
{
  local min="$1" max="$2" cmd ign
  read ign cmd ign < <(caller 0)
  cmd="${cmd#cmd-}"

  shift 2 || INTERNAL 1
  [ $# -ge "$min" ] || OOPS "$cmd" needs at least "$min" arguments
  [ "$min" -gt "$max" -o $# -le "$max" ] || OOPS "$cmd" has no more than "$max" arguments
}

# help [command]: print help to command
#	Without command just list all available commands.
#	With command, it outputs complete help to command.
cmd-help()
{
  args 0 1 "$@"
  if [ 0 = $# ]
  then
	while IFS=' ' read -ru6 pfx line
	do
		[ '#' = "$pfx" ] || continue
		printf 'Usage: %q %s\n' "${0##*/}" "$line"
	done 6<"$0"
	return 0
  fi

  while IFS=' ' read -ru6 pfx cmd line
  do
	[ '#' = "$pfx" ] || continue
	[ ".$cmd" = ".$1" ] || continue
	printf 'Usage: %q %s\n' "${0##*/}" "$cmd $line"
	while IFS=$'\t' read -ru6 pfx line
	do
		[ '#' = "$pfx" ] || break
		printf '#\t%s\n' "$line"
	done
	return 0
  done 6<"$0"
  OOPS no help 'for' command "$1"
}

[ 0 = $# ] && usage

declare -f "cmd-$1" >/dev/null ||
OOPS unknown command, try help: "$1"

"cmd-$1" "${@:2}"

