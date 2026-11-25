# Dev Container Features

This repository publishes the `codex` and `codex-shared` Dev Container Features to GitHub Container Registry.

## Features

| Feature                                      | Purpose                                                                                    | Version |
|----------------------------------------------|--------------------------------------------------------------------------------------------|---------|
| [`codex`](src/codex/README.md)               | Installs the official Codex CLI and persists the container Codex home.                     | `0.1.0` |
| [`codex-shared`](src/codex-shared/README.md) | Optionally shares authentication, transcripts, plugins, and selected config from the host. | `0.1.0` |

## Usage

After publishing, reference the Features in `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/chrisbraucker/devcontainer-features/codex:0.1.0": {},
    "ghcr.io/chrisbraucker/devcontainer-features/codex-shared:0.1.0": {
      "shareAuth": false,
      "shareTranscripts": false,
      "sharePlugins": false
    }
  }
}
```

The host `~/.codex` directory must exist when `codex-shared` is included, even when its sharing options are false.

## Publishing

The `Publish Dev Container Features` workflow publishes all Features under `src/` to GHCR when manually run on `main`.

Feature versions come from each `devcontainer-feature.json` and should be updated before publishing a changed Feature.

GHCR packages are private by default and must be made public in package settings before anonymous users can consume them.

The workflow follows the [official Feature starter](https://github.com/devcontainers/feature-starter) and [publishing action](https://github.com/devcontainers/action).
