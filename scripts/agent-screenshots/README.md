# Agent screenshots

Generates the Claude Code and Codex CLI images in `screenshots/claude/` and `screenshots/codex/`. One image per theme variant, 16 in total.

## Run

```sh
just agent-screenshots
```

Run it again after changing a theme, or after upgrading Claude Code or Codex. The images show the installed program versions. Review them, then commit.

## Requirements

- macOS. The terminal emulator draws glyphs from system fonts, so Linux output differs.
- Go (`nix develop` provides it).
- `claude` and `codex` on `PATH`, both logged in. The test uses your real `HOME` for credentials.
- Both themes installed. Run `just link-claude link-codex-cli` first, because the programs load `extras/` themes from `~/.claude/themes` and `~/.codex/themes`.
- Network access, because the Claude status line runs `npx @owloops/claude-powerline`.

## How it works

[tui-test](https://github.com/microsoft/tui-test) runs each program in a pseudo-terminal behind a terminal emulator and renders the screen to PNG. For each variant, `screenshots_test.go`:

1. Reads the foreground, background, cursor, and 16 ANSI colors from `extras/kitty/8th-Light-<Variant>.conf` and gives them to the emulator as its profile. This stands in for selecting the matching Kitty theme.
2. Starts the program at 120x36 in `/tmp/8l-demo` with a cleared environment, so it does not inherit variables from the shell that runs the test.
3. Selects the theme through flags, so your own settings stay unchanged.
4. Drives the program to a screen, captures it, and crops the emulator's window frame.

| Program | Theme selection | Isolation | Screen |
| --- | --- | --- | --- |
| Claude Code | `--settings` sets `theme` to `custom:8th-Light-<Variant>` and a status line from `extras/claude-powerline/` | `--setting-sources project` skips your user settings, hooks, plugins, and announcements | The prompt with a typed line, so the input border and Powerline show |
| Codex CLI | `-c tui.theme="8th-Light-<Variant>"` | `-c check_for_update_on_startup=false`, and `-a on-request -s workspace-write` replace local approval and sandbox settings | The `/theme` picker with its live syntax preview |

The Powerline preset is copied to a temporary file with only the directory, model, and context segments, so no usage costs appear.

## Things to know

- The first Claude run shows a trust prompt for `/tmp/8l-demo`. The test answers it, and Claude records the folder in `~/.claude.json`. Later runs skip the prompt.
- Claude's startup tip changes between runs, so a regenerated Claude image can differ even when no theme changed.
- The Claude image does not open `/theme`. A custom `~/.claude/keybindings.json` can bind Enter to a newline, which stops the test from submitting the command.
- tui-test 0.1.1 crashes when Go's garbage collector shrinks a stack during a cell read. The recipe sets `GODEBUG=gcshrinkstackoff=1`. Set it yourself when you run `go test` directly.
- Screens are polled with a 45-second limit. A program that changes its text breaks the matching strings in `screenshots_test.go`. The failure prints the screen it saw.

## Run directly

```sh
cd scripts/agent-screenshots
GODEBUG=gcshrinkstackoff=1 AGENT_SCREENSHOTS=/tmp/shots AGENT_SCREENSHOT_VARIANTS=Charcoal,White go test -count=1 -v ./...
```

`AGENT_SCREENSHOTS` is the output directory. Without it the tests skip. `AGENT_SCREENSHOT_VARIANTS` is an optional comma-separated list that limits the run. Use `-run TestClaude` or `-run TestCodex` to run one program.

## Add a screen or program

Add a test beside `TestClaude` and `TestCodex`. Use `launch` to start the program, `waitForAny` to wait for text, `typeSlowly` or `press` to send input, and `capture` to write the image. Add the new directory to the variant coverage list in the `check` recipe of the `justfile`.
