#!/bin/sh
set -eu

REMOTE_USER=$_REMOTE_USER
REMOTE_HOME=$_REMOTE_USER_HOME

mkdir -p /var/lib/codex-home
chown "$REMOTE_USER" /var/lib/codex-home

codex_home=$REMOTE_HOME/.codex
if [ -L "$codex_home" ]; then
  if [ "$(readlink "$codex_home")" != /var/lib/codex-home ]; then
    echo "Refusing to replace existing Codex home symlink: $codex_home" >&2
    exit 1
  fi
elif [ -e "$codex_home" ]; then
  echo "Refusing to replace existing Codex home: $codex_home" >&2
  exit 1
else
  ln -s /var/lib/codex-home "$codex_home"
fi

VERSION=$VERSION

case "$(uname -s)" in
  Linux) ;;
  *)
    echo "The Codex feature currently supports Linux containers only." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) target=x86_64-unknown-linux-musl ;;
  aarch64 | arm64) target=aarch64-unknown-linux-musl ;;
  *)
    echo "Unsupported Codex architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

for command in curl tar sha256sum awk grep sed mktemp; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required to install Codex." >&2
    exit 1
  fi
done

if [ "$VERSION" = "latest" ]; then
  release_json=$(curl -fsSL https://api.github.com/repos/openai/codex/releases/latest)
  VERSION=$(printf '%s\n' "$release_json" |
    sed -n 's/.*"tag_name":[[:space:]]*"rust-v\([^"]*\)".*/\1/p' |
    sed -n '1p')
fi

if ! printf '%s\n' "$VERSION" |
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-alpha(\.[0-9]+){0,2}|-beta(\.[0-9]+)?)?$'; then
  echo "Invalid Codex version: $VERSION" >&2
  exit 1
fi

if [ -e /usr/local/bin/codex ] || [ -L /usr/local/bin/codex ]; then
  echo "Refusing to replace existing /usr/local/bin/codex." >&2
  exit 1
fi

standalone=/opt/codex/packages/standalone
release_root=$standalone/releases
release_dir=$release_root/$VERSION-$target
if [ -e "$release_dir" ] || [ -L "$release_dir" ] ||
  [ -e "$standalone/current" ] || [ -L "$standalone/current" ]; then
  echo "A Codex standalone installation already exists under /opt/codex." >&2
  exit 1
fi

asset=codex-package-$target.tar.gz
release_url=https://github.com/openai/codex/releases/download/rust-v$VERSION
tmp_dir=$(mktemp -d)
stage=
cleanup() {
  if [ -n "$stage" ]; then
    rm -rf "$stage"
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

curl -fsSL "$release_url/$asset" -o "$tmp_dir/$asset"
curl -fsSL "$release_url/codex-package_SHA256SUMS" -o "$tmp_dir/checksums"

expected_digest=$(awk -v asset="$asset" '
  $2 == asset && length($1) == 64 && $1 !~ /[^0-9a-fA-F]/ {
    print tolower($1)
    exit
  }
' "$tmp_dir/checksums")
if [ -z "$expected_digest" ]; then
  echo "No SHA-256 checksum found for $asset." >&2
  exit 1
fi

actual_digest=$(sha256sum "$tmp_dir/$asset" | awk '{print $1}')
if [ "$actual_digest" != "$expected_digest" ]; then
  echo "Codex package checksum verification failed." >&2
  exit 1
fi

mkdir -p "$release_root"
stage=$(mktemp -d "$release_root/.staging.XXXXXX")
tar -xzf "$tmp_dir/$asset" -C "$stage"

for file in \
  "$stage/codex-package.json" \
  "$stage/bin/codex" \
  "$stage/bin/codex-code-mode-host" \
  "$stage/bin/codex-exec-server" \
  "$stage/codex-resources/bwrap" \
  "$stage/codex-path/rg"; do
  if [ ! -f "$file" ]; then
    echo "Codex package is missing required file: $file" >&2
    exit 1
  fi
done

chmod 0755 \
  "$stage/bin/codex" \
  "$stage/bin/codex-code-mode-host" \
  "$stage/bin/codex-exec-server" \
  "$stage/codex-resources/bwrap" \
  "$stage/codex-path/rg"
"$stage/bin/codex" --version >/dev/null

mv "$stage" "$release_dir"
stage=
mkdir -p /usr/local/bin
ln -s "$release_dir" "$standalone/current"
ln -s "$standalone/current/bin/codex" /usr/local/bin/codex
