#!/bin/sh
printf '\033c\033]0;%s\a' Fantasy Guild Manager
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Fantasy Guild Manager LINUX.x86_64" "$@"
