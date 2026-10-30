#!/usr/bin/env python3
"""Check consumer formats, text contrast, and safe installation behavior."""

import importlib.util
import json
import os
import plistlib
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("agent_themes", ROOT / "scripts/generate-agent-themes.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
HEX = re.compile(r"^#[0-9A-F]{6}$")
SEGMENTS = {"directory", "git", "model", "session", "block", "today", "month", "tmux",
            "context", "contextWarning", "contextCritical", "metrics", "version", "env",
            "weekly", "agent", "thinking", "cacheTimer", "outputStyle"}


def check_formats():
    _, variants = generator.load_palette()
    for v in variants:
        name = "8th-Light-" + v["name"]
        theme = json.loads((ROOT / "extras/claude" / (name + ".json")).read_text())
        assert theme["base"] == ("light" if v["light"] else "dark")
        assert theme["name"] == "8th Light " + v["name"].replace("-", " ")
        assert all(HEX.fullmatch(c) for c in theme["overrides"].values())
        for key in ("text", "inactive", "claude", "success", "error", "warning"):
            assert generator.contrast(theme["overrides"][key], v["background"]) >= 4.5, (name, key)
        for key in ("diffAdded", "diffRemoved", "diffAddedWord", "diffRemovedWord"):
            assert generator.contrast(v["foreground"], theme["overrides"][key]) >= 4.5, (name, key)

        config = json.loads((ROOT / "extras/claude-powerline" / (name + ".json")).read_text())
        assert config["theme"] == "custom"
        assert config["display"]["colorCompatibility"] == "truecolor"
        assert set(config["colors"]["custom"]) == SEGMENTS
        for key, pair in config["colors"]["custom"].items():
            assert set(pair) == {"bg", "fg"}
            assert all(HEX.fullmatch(c) for c in pair.values())
            assert generator.contrast(pair["fg"], pair["bg"]) >= 4.5, (name, key)

        with (ROOT / "extras/codex-cli" / (name + ".tmTheme")).open("rb") as f:
            syntax = plistlib.load(f)
        defaults = syntax["settings"][0]["settings"]
        assert defaults["background"] == v["background"]
        assert defaults["foreground"] == v["foreground"]
        scopes = set()
        for rule in syntax["settings"][1:]:
            assert rule["scope"] and rule["settings"]["foreground"]
            scopes.update(rule["scope"].split(", "))
            assert generator.contrast(rule["settings"]["foreground"], v["background"]) >= 4.5, (name, rule["name"])
        assert {"keyword", "string", "comment", "constant", "markup.inserted", "markup.deleted"} <= scopes

        app = json.loads((ROOT / "extras/codex-app" / (name + ".json")).read_text())
        share = (ROOT / "extras/codex-app" / (name + ".codex-theme")).read_text().strip()
        prefix = "codex-theme-v1:"
        assert share.startswith(prefix) and json.loads(share[len(prefix):]) == app
        assert set(app) == {"codeThemeId", "theme", "variant"}
        assert app["codeThemeId"] == "codex"  # A real built-in ID accepted by the app importer.
        assert app["variant"] == theme["base"]
        chrome = app["theme"]
        assert set(chrome) == {"accent", "contrast", "fonts", "ink", "opaqueWindows", "semanticColors", "surface"}
        assert chrome["surface"] == v["background"] and chrome["ink"] == v["foreground"]
        assert 0 <= chrome["contrast"] <= 100 and isinstance(chrome["opaqueWindows"], bool)
        assert chrome["fonts"] == {"code": None, "ui": None}
        assert set(chrome["semanticColors"]) == {"diffAdded", "diffRemoved", "skill"}
        assert all(HEX.fullmatch(c) for c in chrome["semanticColors"].values())


def check_installers():
    with tempfile.TemporaryDirectory(prefix="8l-themes-check-") as temporary:
        base = Path(temporary)
        env = {**os.environ, "CLAUDE_CONFIG_DIR": str(base / "claude config"), "CODEX_HOME": str(base / "codex config")}
        for app, target, extension in (
            ("claude", base / "claude config/themes", ".json"),
            ("claude-powerline", base / "claude config/powerline/themes", ".json"),
            ("codex-cli", base / "codex config/themes", ".tmTheme"),
        ):
            def run(action):
                return subprocess.run(["bash", str(ROOT / "scripts/link-agent-themes.sh"), action, app],
                                      env=env, capture_output=True, text=True)

            # Repeated installation and removal work with spaces in user paths.
            for _ in range(2):
                result = run("link")
                assert result.returncode == 0, result.stderr
            links = list(target.glob("*" + extension))
            assert len(links) == 8 and all(p.is_symlink() and p.exists() for p in links)
            # Uninstall preserves another checkout's link and any user-owned file.
            foreign = target / ("8th-Light-Black" + extension)
            foreign.unlink()
            foreign.symlink_to(base / "another-checkout")
            owned = target / ("8th-Light-Charcoal" + extension)
            owned.unlink()
            owned.write_text("user configuration\n")
            assert run("unlink").returncode == 0
            assert foreign.is_symlink() and owned.read_text() == "user configuration\n"
            # A conflict anywhere in the set fails before modifying any link.
            assert run("link").returncode != 0
            assert foreign.readlink() == base / "another-checkout"
            assert len(list(target.iterdir())) == 2
            owned.unlink()
            foreign.unlink()
            assert run("link").returncode == 0
            assert run("unlink").returncode == 0
            assert run("unlink").returncode == 0
            assert list(target.iterdir()) == []


if __name__ == "__main__":
    check_formats()
    check_installers()
    print("Agent themes: formats, contrast, and install/uninstall checks passed.")
