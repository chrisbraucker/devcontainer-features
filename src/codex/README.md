# Codex CLI

Installs the official standalone Codex CLI package into /opt/codex.

The feature currently supports Linux x86-64 and ARM64 containers.

It uses the matching musl release package, verifies the published SHA-256 checksum, and exposes the CLI as /usr/local/bin/codex.

The complete package stays intact so Codex can find its helper binaries, ripgrep, and Linux sandbox resource.

## Options

- version: Codex release version, or latest (default).

An explicit version can be pinned in devcontainer.json to keep rebuilds reproducible.

The feature does not configure CODEX_HOME; Codex uses the container user's default ~/.codex.
