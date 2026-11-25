# Codex Shared State (codex-shared)

Shares selected state from the host's `~/.codex` with the Codex feature.

## Feature Version

`0.1.0`

## Example Usage

For a `.devcontainer/devcontainer.json` in this repository, add:

```json
{
  "features": {
    "../src/codex": {},
    "../src/codex-shared": {
      "shareAuth": false,
      "shareTranscripts": false,
      "sharePlugins": false
    }
  }
}
```

## Options

Options Id | Description | Type | Default Value
--- | --- | --- | ---
`shareAuth` | Link the host `auth.json` into the container Codex home. | boolean | `false`
`shareTranscripts` | Link host `sessions/` and `archived_sessions/` directories into the container Codex home. | boolean | `false`
`sharePlugins` | Link host `plugins/` and copy the host `[plugins.*]` configuration table once. | boolean | `false`

## Behavior and Limitations

This feature requires the `codex` feature and installs after it.

The host `~/.codex` directory is mounted read-write at `/var/lib/codex-host` whenever this feature is included, even when all sharing options are false.

The `codex` feature stores the container's `~/.codex` in its own named volume, so container state persists across rebuilds without using the host directory as the container home.

Both features assume Codex uses the default `~/.codex`; a custom `CODEX_HOME` bypasses the volume and shared links.

The feature prepares shared links and config on each container start, after the mounts are available and before user-defined lifecycle commands.

Config sections are seeded only once, using markers in the persistent Codex home.

The Dev Containers Python feature is added to parse and write TOML safely.

The `[tui]` and `[marketplaces.*]` tables are copied once from the host `config.toml`, replacing same-named tables in the container config on that first copy.

The `[plugins.*]` table is copied once when `sharePlugins` is enabled, replacing the same-named table in the container config.

It remains in the container config if `sharePlugins` is later disabled.

`personality` and other top-level config keys are not copied.

Local marketplace entries are supported only when their `source_type` is `local` and their source resolves within the host `~/.codex` tree.

Local marketplace sources must be written as `~/.codex/...` or absolute host paths below `~/.codex`, and must resolve within the mounted tree.

The feature remaps accepted paths to `/var/lib/codex-host/...`.

Local marketplace paths outside that tree, including paths that resolve outside the mounted tree through symlinks, fail the feature's post-start setup with an error.

Marketplace catalogs outside `~/.codex`, including those under `~/.agents/plugins`, are not supported or mounted by this feature.

The host `~/.codex` directory must exist before the container is created.

Existing files or links at container destinations are preserved by failing setup with an error.

> **Warning:** `shareTranscripts` makes `~/.codex/sessions` a symlink to `/var/lib/codex-host/sessions`, outside the container's `CODEX_HOME` path.
> Codex has a reported limitation where thread/fork can fail for rollouts reached through a symlinked `sessions/` directory, even when other transcript operations work.
> See [Codex issue #39504](https://github.com/openai/codex/issues/39504) before relying on fork with shared transcripts.
