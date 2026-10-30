#!/usr/bin/env python3
"""Generate agent integrations from the existing Neovim palette and variants."""

import argparse
import json
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_palette():
    source = (ROOT / "lua/eighth_light/init.lua").read_text()
    palette = dict(re.findall(r'(\w+) = "(#[0-9A-F]{6})"', source.split("local variants =")[0]))
    variants = []
    section = source.split("local variants = {", 1)[1].split("local function", 1)[0]
    for block in re.findall(r'\{([^{}]+)\}', section):
        values = dict(re.findall(r'(\w+) = palette\.(\w+)', block))
        variant = {key: palette[value] for key, value in values.items()}
        variant["name"] = re.search(r'name = "([^"]+)"', block)[1]
        variant["light"] = "light = true" in block
        variant["restrained"] = "restrained = true" in block
        variants.append(variant)
    assert len(variants) == 8, "Expected eight Neovim variants"
    return palette, variants


def rgb(color):
    return tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))


def luminance(color):
    channels = [c / 255 for c in rgb(color)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def blend(a, b, amount):
    return "#" + "".join(f"{round(x * amount + y * (1 - amount)):02X}" for x, y in zip(rgb(a), rgb(b)))


def readable(color, background):
    """Preserve an accent when readable; otherwise shade it toward black or white."""
    if contrast(color, background) >= 4.5:
        return color
    target = max(("#000000", "#FFFFFF"), key=lambda c: contrast(c, background))
    for step in range(1, 101):
        adjusted = blend(target, color, step / 100)
        if contrast(adjusted, background) >= 4.5:
            return adjusted
    return target


def syntax(p, v):
    if v["restrained"]:
        colors = (p["black"], p["blue"], p["dark_gray"], p["indigo"], p["black"], p["blue_255"])
    elif v["light"]:
        colors = (p["blue_255"], p["blue"], p["blue"], p["indigo"], p["blue"], p["red"])
    else:
        colors = (p["violet"], p["cyan"], p["green"], p["orange"], p["yellow"], p["indigo"])
    return dict(zip(("keyword", "function", "string", "constant", "type", "special"),
                    (readable(c, v["background"]) for c in colors)))


def claude(p, v):
    bg, fg = v["background"], v["foreground"]
    text = lambda key: readable(p[key], bg)
    overrides = {
        "claude": text("cyan"), "claudeShimmer": text("green"),
        "text": fg, "inverseText": bg, "inactive": readable(v["muted"], bg),
        "subtle": v["border"], "suggestion": text("cyan"),
        "permission": text("cyan"), "permissionShimmer": text("blue"),
        "remember": text("indigo"), "success": text("green"),
        "error": text("red"), "warning": text("orange"), "warningShimmer": text("yellow"),
        "merged": text("violet"), "promptBorder": text("cyan"),
        "promptBorderShimmer": text("green"), "planMode": text("indigo"),
        "autoAccept": text("green"), "bashBorder": text("orange"), "ide": text("cyan"),
        "fastMode": text("yellow"), "fastModeShimmer": text("orange"),
        "effortUltra": text("violet"), "inactiveShimmer": fg,
        "diffAdded": blend(p["green"], bg, 0.12),
        "diffRemoved": blend(p["red"], bg, 0.12),
        "diffAddedDimmed": blend(p["green"], bg, 0.06),
        "diffRemovedDimmed": blend(p["red"], bg, 0.06),
        "diffAddedWord": blend(p["green"], bg, 0.22),
        "diffRemovedWord": blend(p["red"], bg, 0.22),
        "userMessageBackground": v["surface"], "userMessageBackgroundHover": v["surface_alt"],
        "bashMessageBackgroundColor": v["surface"], "memoryBackgroundColor": v["surface"],
        "selectionBg": v["selection"], "composerSidebarBackground": v["surface"],
        "rate_limit_fill": text("cyan"), "rate_limit_empty": v["border"],
        "briefLabelYou": readable(v["muted"], bg), "briefLabelClaude": text("cyan"),
    }
    for name, key in {"red": "red", "blue": "blue", "green": "green", "yellow": "yellow",
                      "purple": "violet", "orange": "orange", "pink": "indigo", "cyan": "cyan"}.items():
        overrides[f"{name}_FOR_SUBAGENTS_ONLY"] = text(key)
    for key in ("red", "orange", "yellow", "green", "blue", "indigo", "violet"):
        overrides[f"rainbow_{key}"] = text(key)
        overrides[f"rainbow_{key}_shimmer"] = readable(blend(p[key], fg, 0.7), bg)
    return {"name": "8th Light " + v["name"].replace("-", " "),
            "base": "light" if v["light"] else "dark", "overrides": overrides}


def powerline(p, v):
    def pair(bg, fg):
        return {"bg": bg, "fg": readable(fg, bg)}
    surface, alt = v["surface"], v["surface_alt"]
    colors = {
        "directory": pair(p["blue"], p["white"]),
        "git": pair(alt, p["green"]), "model": pair(p["indigo"], p["white"]),
        "session": pair(surface, p["yellow"]), "block": pair(alt, p["cyan"]),
        "today": pair(alt, p["orange"]), "month": pair(surface, p["yellow"]),
        "tmux": pair(surface, v["foreground"]), "context": pair(p["cyan"], p["white"]),
        "contextWarning": pair(p["yellow"], p["black"]),
        "contextCritical": pair(p["red"], p["black"]),
        "metrics": pair(p["violet"], p["white"]), "version": pair(alt, v["foreground"]),
        "env": pair(surface, v["foreground"]), "weekly": pair(alt, p["cyan"]),
        "agent": pair(p["indigo"], p["white"]), "thinking": pair(surface, p["indigo"]),
        "cacheTimer": pair(alt, p["green"]), "outputStyle": pair(surface, p["cyan"]),
    }
    return {"theme": "custom", "display": {"style": "powerline", "colorCompatibility": "truecolor"},
            "colors": {"custom": colors}}


def codex_cli(p, v):
    s = syntax(p, v)
    def rule(name, scope, color, style=None):
        settings = {"foreground": color}
        if style:
            settings["fontStyle"] = style
        return {"name": name, "scope": scope, "settings": settings}
    return {"name": "8th Light " + v["name"].replace("-", " "),
            "settings": [{"settings": {
                "background": v["background"], "foreground": v["foreground"],
                "caret": p["green"], "selection": v["selection"],
                "lineHighlight": v["surface"], "invisibles": v["border"],
            }},
            rule("Comments", "comment, punctuation.definition.comment", readable(v["muted"], v["background"]), "italic"),
            rule("Keywords", "keyword, storage", s["keyword"]),
            rule("Strings", "string", s["string"]),
            rule("Constants", "constant", s["constant"]),
            rule("Functions", "entity.name.function, support.function", s["function"]),
            rule("Types", "entity.name.type, entity.name.class, support.type, support.class", s["type"]),
            rule("Special", "constant.character.escape, entity.name.tag, keyword.other.special-method", s["special"]),
            rule("Variables", "variable", v["foreground"]),
            rule("Headings", "markup.heading, entity.name.section", s["type"], "bold"),
            rule("Links", "markup.underline.link", s["function"], "underline"),
            rule("Inserted", "markup.inserted", readable(p["green"], v["background"])),
            rule("Deleted", "markup.deleted, invalid", readable(p["red"], v["background"])),
            rule("Changed", "markup.changed", s["constant"]),
            rule("Bold", "markup.bold", v["foreground"], "bold"),
            rule("Italic", "markup.italic", v["foreground"], "italic")]}


def codex_app(p, v):
    # The app importer accepts only built-in codeThemeId values, not .tmTheme slugs.
    return {"codeThemeId": "codex", "theme": {
        "accent": p["cyan"], "contrast": 60 if not v["light"] else 45,
        "fonts": {"code": None, "ui": None}, "ink": v["foreground"],
        "opaqueWindows": True,
        "semanticColors": {"diffAdded": readable(p["green"], v["background"]),
                           "diffRemoved": readable(p["red"], v["background"]),
                           "skill": readable(p["indigo"], v["background"])},
        "surface": v["background"]}, "variant": "light" if v["light"] else "dark"}


def outputs():
    p, variants = load_palette()
    for v in variants:
        name = "8th-Light-" + v["name"]
        for folder, data in (("claude", claude(p, v)), ("claude-powerline", powerline(p, v)),
                             ("codex-app", codex_app(p, v))):
            yield ROOT / "extras" / folder / (name + ".json"), (json.dumps(data, indent=2) + "\n").encode()
        yield ROOT / "extras/codex-cli" / (name + ".tmTheme"), plistlib.dumps(codex_cli(p, v), sort_keys=False)
        share = "codex-theme-v1:" + json.dumps(codex_app(p, v), separators=(",", ":")) + "\n"
        yield ROOT / "extras/codex-app" / (name + ".codex-theme"), share.encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if checked-in themes differ from the source palette")
    args = parser.parse_args()
    stale = []
    for path, content in outputs():
        if args.check:
            if not path.exists() or path.read_bytes() != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
    if stale:
        parser.exit(1, "Regenerate agent themes: python3 scripts/generate-agent-themes.py\n" + "\n".join(stale) + "\n")


if __name__ == "__main__":
    main()
