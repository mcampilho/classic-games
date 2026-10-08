#!/bin/sh
printf '\033c\033]0;%s\a' Arcade Clássico
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ArcadeClassico.x86_64" "$@"
