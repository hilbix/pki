#!/bin/bash

STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2; return $e; }
WARN() { STDERR WARN: "$@"; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
INTERNAL() { read line cmd name < <(caller ${1:-0}); OOPS internal error in "$name" line "$line" function "$cmd"; }
NOTYET() { read line cmd name < <(caller ${1:-0}); OOPS "$name:$line:" "$cmd" not yet implemented; }
x() { "$@"; }
o() { x "$@" || OOPS fail with rc=$?: "$@"; }
v() { local ___v ___r; ___v="$("${@:2}"x)" || OOPS fail with rc=$?: "${@:2}"; ___v="${___v%x}"; ___v="${___v%$'\n'}"; printf -v "$1" %s "$___v"; return 0; }

CONFDIR="$HOME/.pki.conf.d"

usage()
{
  {
  printf 'Usage: %q command [args..]\n' "${0##*/}"
  printf '\tEasy to use wrapper to OpenSSL\n'
  printf '\tUse command "help" to list all commands\n'
  } >&2
  exit 42
}

# load config
load()
{
  {
	[ -d "$CONFDIR" ] &&
		[ -s "$CONFDIR/pki.conf" ] &&
		. "$CONFDIR/pki.conf" &&
		[ -n "$PKI_KEY" ] &&
		[ -s "$CONFDIR/$PKI_KEY.key" ]
  } || OOPS please run setup first
}

# save config
save()
{
  {
  printf '# WARNING! AUTOMATICALLY GENERATED,\n'
  printf '# WILL BE OVERWRITTEN UNCONDITIONALLY\r\n'
  for a in ${!PKI_@}
  do
	printf '%s="${%s-%q}"\n' "$a" "$a" "${!a}"
  done
  } > "$CONFDIR/pki.conf.tmp" || OOPS cannot write "$CONFDIR/pki.conf.tmp"

  cmp -s "$CONFDIR/pki.conf" "$CONFDIR/pki.conf.tmp" && return
  [ ! -s "$CONFDIR/pki.conf" ] || confirm overwrite "$CONFDIR/pki.conf" || return
  o mv -f "$CONFDIR/pki.conf.tmp" "$CONFDIR/pki.conf"
}

tty2()
{
  tty <&2 >/dev/null || OOPS stderr is not a TTY
}

ask()
{
  local ans t

  t='Y/n'
  [ n = "$1" ] && t='y/N'
  while	tty2
	ans=
	IFS='' read -rsp"$2 [$t]? " -n1 -u2 ans >&2 || exit
	case "${ans:-"$1"}" in
	($'\e')	printf 'ESC\r\n' >&2; exit 1;;
	(n|N)	printf 'n\r\n' >&2; return 1;;
	(y|Y)	printf 'y\r\n' >&2; return 0;;
	esac
	printf '?\r\n'
  do :; done
  return 1
}

confirm()
{
  ask y "$*"
}

decline()
{
  ! ask n "$*"
}

keep()
{
  ask y "keep $*"
}

enter()
{
  local ___e
  while	read -rp "$1: " -u2 -e -i "${!1}" ___e || exit
	[ 2 -le $# ]
  do
	if	x "${@:2}" "${!1}"
	then
		[ ".$___e" = ".${!1}" ] && break
		confirm use new value "'$___e'" instead of "'${!1}'" && break
	fi
	[ -n "${!1}" ] && ask leave value "'${!1}'" as-is && return
  done
  printf -v "$1" %s "$___e"
}

# Check argument to be a simple name
# This is basically something which can be used as a domain part as well
simplename()
{
  case "$1" in
  (-*|*-|*--*)	return 1;;
  (.*|*.|*..*)	return 1;;
  (*-.*|*.-*)	return 1;;
  (''|*[!-.a-zA-Z0-9]*)	return 1;;
  esac
  return 0
}

# args min max "$@"
# check for "$@" being in the range min..max
# if max<min then max is unlimited
args()
{
  local min="$1" max="$2" cmd ign
  read ign cmd ign < <(caller 0)
  cmd="${cmd#cmd-}"

  shift 2 || INTERNAL 1
  [ $# -ge "$min" ] || OOPS "$cmd" needs at least "$min" arguments
  [ "$min" -gt "$max" -o $# -le "$max" ] || OOPS "$cmd" has no more than "$max" arguments
}

## help [command]:	print help to command
#	Without command just list all available commands.
#	With command, it outputs complete help to command.
cmd-help()
{
  args 0 1 "$@"
  if [ 0 = $# ]
  then
	while read -ru6 pfx line
	do
		[ '##' = "$pfx" ] || continue
		printf 'Usage: %q %s\n' "${0##*/}" "$line"
	done 6<"$0"
	return 0
  fi

  while read -ru6 pfx cmd line
  do
	[ '##' = "$pfx" ] || continue
	[ ".$cmd" = ".$1" ] || [ ".$cmd" = ".$1:" ] || continue
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

#!# init:	automatic setup
#	Same as "setup" with autoanswering questions
cmd-init()
{
  NOTYET
}

## setup:	interactive setup
#	With this command you can change some aspects of this tool
cmd-setup()
{
  args 0 0 "$@"

  PKI_KEY=default

  if	[ ! -d "$CONFDIR" ]
  then
	[ -e "$CONFDIR" ] && OOPS "$CONFDIR" is not a directory
	confirm create directory "$CONFDIR" || OOPS cannot continue
	o mkdir -m700 "$CONFDIR"
  elif	[ -s "$CONFDIR/pki.conf" ]
  then
	( . "$CONFDIR/pki.conf"; exit 0 ) && . "$CONFDIR/pki.conf" || WARN ignoring defective "$CONF/pki.conf"
  fi

  keep default key name "'$PKI_KEY'" || enter PKI_KEY simplename

  if	[ -s "$CONFDIR/$PKI_KEY.key" ]
  then
	! keep key "'$PKI_KEY'"
  else
	ask create key "'$PKI_KEY'"
  fi &&
	newkey "$PKI_KEY"

  save
}

## new [key]:	create a new key
#	key is the key name.  If unnamed, a generated name is used
cmd-new()
{
  args 0 1 "$@"
  load
  key="$1"
  [ 0 = $# ] && printf -v key '%(%Y%m%d-%H%M%S)T.%d' -1 $$
  newkey "$key"
  STDERR : new key
  STDOUT "$key"
}

# newkey name: Create a new public key pair
newkey()
{
  simplename "$1" || OOPS invalid key name: "$1"

  [ -f "$CONFDIR/$1.key" ] &&
	keep existing key "'$1'" &&
	return 1

  ARGS=()
  PASS=()
  if	decline use unprotected key
  then
	# WTF!?!
	# THE REQUIREMENT TO PASS A PASSPHRASE TO OPENSSL
	# IS INSECURE AS HELL!  However there seems to be
	# no way to do it with OpenSSL without entering
	# the passphrase.

	PASSPHRASE="$(genpass 6)"
	enter PASSPHRASE
	PASSOUT+=(-aes128 -passout "pass:$PASSPHRASE")
	PASSIN+=(-passin "pass:$PASSPHRASE")
	PASSPHRASE=
  fi
  o openssl genrsa "${PASSOUT[@]}" -out "$CONFDIR/$1.key" 2>/dev/null
  PASSOUT=
  o openssl rsa -in "$CONFDIR/$1.key" "${PASSIN[@]}" -pubout -out "$CONFDIR/$1.pub" 2>/dev/null
  PASSIN=
}

# genpass N: Create a new passphrase from dict "words"
# N defaults to 5 words
genpass()
{
  printf 'generating passphrase: ' >&2

  let n="${1:-5}" m k l

  [ -s /usr/share/dict/words ] || WARN /usr/share/dict/words missing || return

  m="$(egrep -v '[^a-z]' /usr/share/dict/words | sort -u | wc -l)"
  [ 5 -lt "$m" ] || WARN /usr/share/dict/words too small || return

  l=()
  while	printf %d "$n" >&2
	let n--
  do
	# WTF?  OpenSSL cannot generate numbers in a range?
	let k="1+(0x$(openssl rand -hex 5) % m)"
	l+=("$(egrep -v '[^a-z]' /usr/share/dict/words | sort -uR | sed -n "${k}p")")
  done
  printf '\n' >&2

  echo "${l[@]}"
}

#!# set var val:	direct setup
#	Set defauls of variables
#	See also: setup
cmd-set()
{
  NOTYET
}

#!# get [var..]:	query variables
#	Without variable, list all variables and settings in a shell compatible way
#	With single variable, output just this variable
#	With multiple variables, output shell compatible variable settings
cmd-get()
{
  NOTYET
}

#!# import [file..]:	import or update Public Keys
cmd-import()
{
  NOTYET
}

#!# export [key..]:	export the Public Keys
#	If key is missing, export all known Public Keys
cmd-export()
{
  NOTYET
}

#!# sign [file]:	sign data with the private key
#	If file is missing, stdin is used
#	Signature is written to stdout
cmd-sign()
{
  NOTYET
}

#!# penc [file]:	encrypt data directly with Public Key
#	If file is missing, stdin is used
#	This does not use an intermediate AES key
#	See also: pdec
cmd-penc()
{
  NOTYET
}

#!# pdec [file]:	decryp data directly with your Public Key
#	If file is missing, stdin is used
#	This does not use an intermediate AES key
#	See also: penc
cmd-pdec()
{
  NOTYET
}

#!# dec [file]:	decrypt data with the your Private Key
#	If file is missing, stdin is used
cmd-dec()
{
  NOTYET
}

#!# pub [key..]:	publish data to others
#	Similar to "enc" followed by "add"
#	Typical use: 'pki pub bob <file >file.bob'
cmd-pub()
{
  NOTYET
}

#!# add file [key..]:	add more recipients
#	If key is missing, read keys from stdin
#	See "import" on how to import keys
cmd-add()
{
  NOTYET
}

#!# force cmd [args..]:	force a command
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

