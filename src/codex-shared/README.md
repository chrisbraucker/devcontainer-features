# Codex Shared State

Mounts the host's ~/.codex directory at /var/lib/codex.

The full mounted directory is accessible inside the container whenever this feature is included, even when both options are false.

shareAuth links only the host auth.json into the container's default ~/.codex.

shareTranscripts links the host sessions/ and archived_sessions/ directories into the container's default ~/.codex.

The options default to false, and existing files or links at the container destinations are preserved by failing installation with an error.

The mount is read-write so Codex can refresh authentication and write transcripts.

This feature assumes Codex uses the container user's default ~/.codex; it does not configure a custom CODEX_HOME.

> **Warning:** shareTranscripts makes ~/.codex/sessions a symlink to /var/lib/codex/sessions, outside CODEX_HOME. Codex has a reported limitation where thread/fork can fail for rollouts reached through a symlinked sessions/ directory, even when other transcript operations work. See [Codex issue #39504](https://github.com/openai/codex/issues/39504) before relying on fork with shared transcripts.

The host ~/.codex directory must exist before the container is created.

## Options

- shareAuth: share the host auth file (default false).
- shareTranscripts: share active and archived rollout files (default false).
