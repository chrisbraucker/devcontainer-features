# Codex CLI (codex)

Installs the official standalone Codex CLI package into `/opt/codex`.

## Feature Version

`0.1.0`

## Example Usage

For a `.devcontainer/devcontainer.json` in this repository, add:

```json
{
  "features": {
    "../src/codex": {
      "version": "latest"
    }
  }
}
```

## Options

Options Id | Description | Type | Default Value
--- | --- | --- | ---
`version` | Codex release version to install. | string | `latest`

An explicit Codex release can be pinned to keep rebuilds reproducible.

## OS Support

The feature supports Linux x86-64 and ARM64 containers.

It installs the matching musl release package, verifies the published SHA-256 checksum, and exposes the CLI as `/usr/local/bin/codex`.

The complete package stays intact so Codex can find its helper binaries, ripgrep, and Linux sandbox resource.

The feature mounts a named volume at `/var/lib/codex-home` and links the container user's `~/.codex` to it.

The volume persists Codex data across container rebuilds and is scoped to the Dev Container instance.

The feature assumes Codex uses the default `~/.codex` path; a custom `CODEX_HOME` bypasses this volume.
