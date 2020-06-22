#!/bin/bash

STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@"; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
INTERNAL() { read line cmd name < <(caller ${1:-0}); OOPS internal error in "$name" line "$line" function "$cmd"; }
NOTYET() { read line cmd name < <(caller ${1:-0}); OOPS "$name:$line:" "$cmd" not yet implemented; }

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

# help [command]:	print help to command
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

# init:	automatic setup
#	Same as "setup" with autoanswering questions
cmd-init()
{
  NOTYET
}

# setup:	interactive setup
#	With this command you can change some aspects of this tool
cmd-setup()
{
  NOTYET
}

# set var val:	direct setup
#	Set defauls of variables
#	See also: setup
cmd-set()
{
  NOTYET
}

# get [var..]:	query variables
#	Without variable, list all variables and settings in a shell compatible way
#	With single variable, output just this variable
#	With multiple variables, output shell compatible variable settings
cmd-get()
{
  NOTYET
}

# import [file..]:	import or update Public Keys
cmd-import()
{
  NOTYET
}

# export [key..]:	export the Public Keys
#	If key is missing, export all known Public Keys
cmd-export()
{
  NOTYET
}

# sign [file]:	sign data with the private key
#	If file is missing, stdin is used
#	Signature is written to stdout
cmd-sign()
{
  NOTYET
}

# penc [file]:	encrypt data directly with Public Key
#	If file is missing, stdin is used
#	This does not use an intermediate AES key
#	See also: pdec
cmd-penc()
{
  NOTYET
}

# pdec [file]:	decryp data directly with your Public Key
#	If file is missing, stdin is used
#	This does not use an intermediate AES key
#	See also: penc
cmd-pdec()
{
  NOTYET
}

# dec [file]:	decrypt data with the your Private Key
#	If file is missing, stdin is used
cmd-dec()
{
  NOTYET
}

# pub [key..]:	publish data to others
#	Similar to "enc" followed by "add"
#	Typical use: 'pki pub bob <file >file.bob'
cmd-pub()
{
  NOTYET
}

# add file [key..]:	add more recipients
#	If key is missing, read keys from stdin
#	See "import" on how to import keys
cmd-add()
{
  NOTYET
}

# force cmd [args..]:	force a command
#	Automatically always answers questions with 'yes'
#	Most commands are interactive.  This makes them noninteractive.
#	Env: PKI_FORCE=y has the same effect
#	Env: PKI_FORCE=n overrides this command
cmd-force()
{
  NOTYET
}

[ 0 = $# ] && usage

declare -f "cmd-$1" >/dev/null ||
OOPS unknown command, try help: "$1"

"cmd-$1" "${@:2}"

