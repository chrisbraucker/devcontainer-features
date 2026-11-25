#!/bin/sh
set -eu

REMOTE_USER=$_REMOTE_USER
REMOTE_HOME=$_REMOTE_USER_HOME
SHAREAUTH=$SHAREAUTH
SHARETRANSCRIPTS=$SHARETRANSCRIPTS

if [ "$SHAREAUTH" != "true" ] && [ "$SHARETRANSCRIPTS" != "true" ]; then
  exit 0
fi

codex_home=$REMOTE_HOME/.codex
if [ ! -e "$codex_home" ]; then
  mkdir -p "$codex_home"
  chown "$REMOTE_USER" "$codex_home"
fi

link_shared() {
  link_source=$1
  link_target=$2

  if [ -L "$link_target" ]; then
    if [ "$(readlink "$link_target")" = "$link_source" ]; then
      return 0
    fi
    echo "Refusing to replace existing symlink: $link_target" >&2
    exit 1
  fi
  if [ -e "$link_target" ]; then
    echo "Refusing to replace existing Codex data: $link_target" >&2
    exit 1
  fi

  ln -s "$link_source" "$link_target"
}

if [ "$SHAREAUTH" = "true" ]; then
  link_shared /var/lib/codex/auth.json "$codex_home/auth.json"
fi

if [ "$SHARETRANSCRIPTS" = "true" ]; then
  link_shared /var/lib/codex/sessions "$codex_home/sessions"
  link_shared /var/lib/codex/archived_sessions "$codex_home/archived_sessions"
fi
