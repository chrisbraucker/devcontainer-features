import copy
import fcntl
import os
import stat
import tempfile
from pathlib import Path

import tomlkit


HOST_HOME = Path("/var/lib/codex-host")
CODEX_HOME = Path.home() / ".codex"


def option(name):
    return os.environ.get(f"CODEX_SHARED_SHARE_{name}", "false") == "true"


def link_shared(name, source, enabled, directory=False):
    target = CODEX_HOME / name
    source = Path(source)

    if not enabled:
        if target.is_symlink() and os.readlink(target) == str(source):
            target.unlink()
        return

    if target.is_symlink():
        if os.readlink(target) == str(source):
            if directory:
                source.mkdir(parents=True, exist_ok=True)
            return
        raise RuntimeError(f"Refusing to replace existing symlink: {target}")
    if os.path.lexists(target):
        raise RuntimeError(f"Refusing to replace existing Codex data: {target}")
    if directory:
        source.mkdir(parents=True, exist_ok=True)
    target.symlink_to(source, target_is_directory=directory)


def map_marketplace_source(source):
    marker = "~/.codex"
    if source == marker:
        relative = Path()
    elif source.startswith(marker + "/"):
        relative = Path(source[len(marker) + 1 :])
    else:
        host_home = os.environ.get("CODEX_SHARED_HOST_CODEX_HOME")
        if not host_home or not Path(host_home).is_absolute() or not Path(source).is_absolute():
            raise RuntimeError(
                f"Local marketplace source must be an absolute path below the host ~/.codex: {source}"
            )
        try:
            relative = Path(os.path.abspath(source)).relative_to(Path(os.path.abspath(host_home)))
        except ValueError as error:
            raise RuntimeError(
                f"Local marketplace source is outside the host ~/.codex: {source}"
            ) from error

    mounted_source = HOST_HOME / relative
    try:
        mounted_source.resolve().relative_to(HOST_HOME.resolve())
    except ValueError as error:
        raise RuntimeError(
            f"Local marketplace source cannot be reached within the mounted host ~/.codex: {source}"
        ) from error
    return mounted_source.as_posix()


def remap_marketplaces(marketplaces):
    if not hasattr(marketplaces, "values"):
        return
    for marketplace in marketplaces.values():
        if hasattr(marketplace, "get") and marketplace.get("source_type") == "local":
            source = marketplace.get("source")
            if not isinstance(source, str):
                raise RuntimeError("Local marketplace entries must have a string source path.")
            marketplace["source"] = map_marketplace_source(source)


def write_config(config_path, config):
    mode = stat.S_IMODE(config_path.stat().st_mode) if config_path.exists() else 0o600
    if config_path.is_symlink():
        raise RuntimeError(f"Refusing to replace symlinked Codex config: {config_path}")
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=CODEX_HOME, prefix=".config.toml.", delete=False
    ) as temporary:
        temporary.write(tomlkit.dumps(config))
        temporary_path = Path(temporary.name)
    os.chmod(temporary_path, mode)
    os.replace(temporary_path, config_path)


def seed_config(share_plugins):
    host_config = HOST_HOME / "config.toml"
    if not host_config.is_file():
        return

    host = tomlkit.parse(host_config.read_text(encoding="utf-8"))
    config_path = CODEX_HOME / "config.toml"
    common_marker = CODEX_HOME / ".codex-shared-config-v1"
    plugins_marker = CODEX_HOME / ".codex-shared-plugins-v1"
    needs_common = not common_marker.exists()
    needs_plugins = share_plugins and not plugins_marker.exists()
    if not needs_common and not needs_plugins:
        return

    if config_path.is_symlink():
        raise RuntimeError(f"Refusing to modify symlinked Codex config: {config_path}")
    config = tomlkit.parse(config_path.read_text(encoding="utf-8")) if config_path.exists() else tomlkit.document()
    changed = False

    if needs_common:
        for section in ("tui", "marketplaces"):
            if section in host:
                config[section] = copy.deepcopy(host[section])
                if section == "marketplaces":
                    remap_marketplaces(config[section])
                changed = True

    if needs_plugins and "plugins" in host:
        config["plugins"] = copy.deepcopy(host["plugins"])
        changed = True

    if changed:
        write_config(config_path, config)
    if needs_common:
        common_marker.touch(mode=0o600, exist_ok=True)
    if needs_plugins:
        plugins_marker.touch(mode=0o600, exist_ok=True)


def main():
    if not CODEX_HOME.is_dir():
        raise RuntimeError(f"Codex home is not mounted at {CODEX_HOME}; install the codex feature first.")
    if not HOST_HOME.is_dir():
        raise RuntimeError(f"Host Codex home is not mounted at {HOST_HOME}.")

    with (CODEX_HOME / ".codex-shared.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        link_shared("auth.json", HOST_HOME / "auth.json", option("AUTH"))
        link_shared("sessions", HOST_HOME / "sessions", option("TRANSCRIPTS"), directory=True)
        link_shared("archived_sessions", HOST_HOME / "archived_sessions", option("TRANSCRIPTS"), directory=True)
        link_shared("plugins", HOST_HOME / "plugins", option("PLUGINS"), directory=True)
        seed_config(option("PLUGINS"))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(f"codex-shared: {error}") from error
