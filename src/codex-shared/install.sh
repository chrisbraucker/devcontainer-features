#!/bin/sh
set -eu

SHAREAUTH=$SHAREAUTH
SHARETRANSCRIPTS=$SHARETRANSCRIPTS
SHAREPLUGINS=$SHAREPLUGINS

if [ ! -L /usr/local/bin/codex ] ||
  [ "$(readlink /usr/local/bin/codex)" != /opt/codex/packages/standalone/current/bin/codex ]; then
  echo "The codex-shared feature requires the codex feature to be installed first." >&2
  exit 1
fi

python3 -m pip install --quiet --disable-pip-version-check \
  --target /usr/local/lib/codex-shared tomlkit==1.1.0

mkdir -p /usr/local/lib/codex-shared
cp "$(dirname "$0")/prepare.py" /usr/local/lib/codex-shared/prepare.py

shared_command=/usr/local/lib/codex-shared/codex-shared
if [ -e "$shared_command" ] || [ -L "$shared_command" ]; then
  echo "Refusing to replace existing $shared_command." >&2
  exit 1
fi

cat > "$shared_command" <<EOF
#!/bin/sh
set -eu

export CODEX_SHARED_SHARE_AUTH=$SHAREAUTH
export CODEX_SHARED_SHARE_TRANSCRIPTS=$SHARETRANSCRIPTS
export CODEX_SHARED_SHARE_PLUGINS=$SHAREPLUGINS
export PYTHONPATH=/usr/local/lib/codex-shared
exec python3 /usr/local/lib/codex-shared/prepare.py
EOF
chmod 0755 "$shared_command"
