package agentscreenshots_test

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	tuitest "github.com/microsoft/tui-test/bindings/go"
	"github.com/microsoft/tui-test/bindings/go/tuitesttest"
)

var variants = []string{"Black", "Charcoal", "Dark-Gray", "Mid-Gray", "Light-Gray", "Lighter-Gray", "Lightest-Gray", "White"}

const demoDirectory = "/tmp/8l-demo"

func repositoryRoot(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs("../..")
	if err != nil {
		t.Fatal(err)
	}
	return root
}

func kittyColors(t *testing.T, root, variant string) tuitest.Colors {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(root, "extras/kitty/8th-Light-"+variant+".conf"))
	if err != nil {
		t.Fatal(err)
	}
	values := map[string]string{}
	for _, line := range strings.Split(string(data), "\n") {
		fields := strings.Fields(line)
		if len(fields) == 2 && !strings.HasPrefix(fields[0], "#") {
			values[fields[0]] = fields[1]
		}
	}
	c := func(name string) string { return values[name] }
	return tuitest.Colors{
		Foreground: c("foreground"), Background: c("background"), Cursor: c("cursor"),
		Black: c("color0"), Red: c("color1"), Green: c("color2"), Yellow: c("color3"), Blue: c("color4"), Magenta: c("color5"), Cyan: c("color6"), White: c("color7"),
		BrightBlack: c("color8"), BrightRed: c("color9"), BrightGreen: c("color10"), BrightYellow: c("color11"), BrightBlue: c("color12"), BrightMagenta: c("color13"), BrightCyan: c("color14"), BrightWhite: c("color15"),
	}
}

func parseHexColor(hex string) color.Color {
	var red, green, blue uint8
	fmt.Sscanf(hex, "#%02x%02x%02x", &red, &green, &blue)
	return color.RGBA{red, green, blue, 255}
}

func withoutWindowFrame(t *testing.T, source, target string, background color.Color) {
	t.Helper()
	file, err := os.Open(source)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	captured, err := png.Decode(file)
	if err != nil {
		t.Fatal(err)
	}
	bounds := captured.Bounds()
	middle := bounds.Min.X + bounds.Dx()/2
	left, right, top, bottom := bounds.Max.X, bounds.Min.X, bounds.Max.Y, bounds.Min.Y
	contentTop := -1
	wantRed, wantGreen, wantBlue, _ := background.RGBA()
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			if _, _, _, alpha := captured.At(x, y).RGBA(); alpha < 0xff00 {
				continue
			}
			left, right, top, bottom = min(left, x), max(right, x+1), min(top, y), max(bottom, y+1)
		}
		if red, green, blue, alpha := captured.At(middle, y).RGBA(); contentTop < 0 && alpha == 0xffff && red == wantRed && green == wantGreen && blue == wantBlue {
			contentTop = y
		}
	}
	if contentTop < 0 || right <= left || bottom <= contentTop {
		t.Fatalf("could not find the terminal inside %s", source)
	}
	cropped := image.NewNRGBA(image.Rect(0, 0, right-left, bottom-contentTop))
	draw.Draw(cropped, cropped.Bounds(), captured, image.Pt(left, contentTop), draw.Src)
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		t.Fatal(err)
	}
	output, err := os.Create(target)
	if err != nil {
		t.Fatal(err)
	}
	defer output.Close()
	if err := png.Encode(output, cropped); err != nil {
		t.Fatal(err)
	}
}

func screenText(t *testing.T, terminal *tuitest.Client) string {
	t.Helper()
	text, err := terminal.Text(tuitest.TextOptions{})
	if err != nil {
		t.Fatal(err)
	}
	return text
}

// waitForAny polls until one of the needles is on screen and returns it.
func waitForAny(t *testing.T, terminal *tuitest.Client, needles ...string) string {
	t.Helper()
	deadline := time.Now().Add(45 * time.Second)
	for time.Now().Before(deadline) {
		text := screenText(t, terminal)
		for _, needle := range needles {
			if strings.Contains(text, needle) {
				return needle
			}
		}
		time.Sleep(250 * time.Millisecond)
	}
	t.Fatalf("none of %q appeared. Screen:\n%s", needles, screenText(t, terminal))
	return ""
}

func typeSlowly(t *testing.T, terminal *tuitest.Client, text string) {
	t.Helper()
	for _, character := range text {
		if err := terminal.Type(string(character)); err != nil {
			t.Fatal(err)
		}
		time.Sleep(40 * time.Millisecond)
	}
}

func press(t *testing.T, terminal *tuitest.Client, keys ...string) {
	t.Helper()
	for _, key := range keys {
		if err := terminal.Press(key); err != nil {
			t.Fatal(err)
		}
		time.Sleep(300 * time.Millisecond)
	}
}

// cleanEnvironment keeps the agent from inheriting variables of the session that runs the test, such as a parent Claude's markers.
func cleanEnvironment(program string, args []string) (string, []string) {
	env := []string{"TERM=xterm-256color", "COLORTERM=truecolor", "LANG=en_US.UTF-8"}
	for _, name := range []string{"PATH", "HOME", "USER", "LOGNAME", "SHELL"} {
		env = append(env, name+"="+os.Getenv(name))
	}
	return "/usr/bin/env", append(append([]string{"-i"}, env...), append([]string{program}, args...)...)
}

func launch(t *testing.T, program string, args []string, colors tuitest.Colors) *tuitest.Client {
	t.Helper()
	if err := os.MkdirAll(demoDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	path, err := exec.LookPath(program)
	if err != nil {
		t.Skip(err)
	}
	program, args = cleanEnvironment(path, args)
	return tuitesttest.New(t, tuitesttest.Options{
		Program: program,
		Args:    args,
		Spawn: tuitest.SpawnOptions{
			Profile: &tuitest.Profile{Colors: colors},
			Cols:    tuitest.Ptr(uint16(120)), Rows: tuitest.Ptr(uint16(36)), WaitReady: tuitest.Ptr(false),
			Cwd: demoDirectory,
		},
	})
}

func capture(t *testing.T, terminal *tuitest.Client, colors tuitest.Colors, target string) {
	t.Helper()
	raw := filepath.Join(t.TempDir(), "raw.png")
	if _, err := terminal.Screenshot(raw, tuitest.ScreenshotOptions{Transparent: true}); err != nil {
		t.Fatal(err)
	}
	withoutWindowFrame(t, raw, target, parseHexColor(colors.Background))
}

func selectedVariants() []string {
	if only := os.Getenv("AGENT_SCREENSHOT_VARIANTS"); only != "" {
		return strings.Split(only, ",")
	}
	return variants
}

func outputDirectory(t *testing.T, root, agent string) string {
	t.Helper()
	directory := os.Getenv("AGENT_SCREENSHOTS")
	if directory == "" {
		t.Skip("set AGENT_SCREENSHOTS to the directory that receives the screenshots")
	}
	return filepath.Join(directory, agent)
}

func imageName(variant string) string {
	return "8th-light-" + strings.ToLower(variant) + ".png"
}

// claudeStatusLine selects the Powerline preset with only the segments that do not depend on the person running the test.
func claudeStatusLine(t *testing.T, root, variant string) string {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(root, "extras/claude-powerline/8th-Light-"+variant+".json"))
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal(data, &config); err != nil {
		t.Fatal(err)
	}
	display := config["display"].(map[string]any)
	display["lines"] = []any{map[string]any{"segments": map[string]any{
		"directory": map[string]any{"enabled": true},
		"model":     map[string]any{"enabled": true},
		"context":   map[string]any{"enabled": true},
	}}}
	path := filepath.Join(t.TempDir(), "powerline.json")
	data, _ = json.Marshal(config)
	if err := os.WriteFile(path, data, 0o644); err != nil {
		t.Fatal(err)
	}
	return "npx -y @owloops/claude-powerline@latest --style=powerline --theme=custom --config=" + path
}

func TestClaude(t *testing.T) {
	root := repositoryRoot(t)
	directory := outputDirectory(t, root, "claude")
	for _, variant := range selectedVariants() {
		t.Run(variant, func(t *testing.T) {
			colors := kittyColors(t, root, variant)
			settings, _ := json.Marshal(map[string]any{
				"theme":              "custom:8th-Light-" + variant,
				"statusLine":         map[string]any{"type": "command", "command": claudeStatusLine(t, root, variant)},
				"spinnerTipsEnabled": false,
				"model":              "sonnet",
				"permissions":        map[string]any{"defaultMode": "default"},
			})
			terminal := launch(t, "claude", []string{"--setting-sources", "project", "--settings", string(settings)}, colors)
			if waitForAny(t, terminal, "trust this folder", "Claude Code v") == "trust this folder" {
				time.Sleep(2 * time.Second)
				press(t, terminal, "Down")
				waitForAny(t, terminal, "❯ Yes")
				press(t, terminal, "Enter")
				waitForAny(t, terminal, "Claude Code v")
			}
			time.Sleep(3 * time.Second)
			typeSlowly(t, terminal, "Explain how this repository is organized")
			time.Sleep(time.Second)
			capture(t, terminal, colors, filepath.Join(directory, imageName(variant)))
		})
	}
}

func TestCodex(t *testing.T) {
	root := repositoryRoot(t)
	directory := outputDirectory(t, root, "codex")
	for _, variant := range selectedVariants() {
		t.Run(variant, func(t *testing.T) {
			colors := kittyColors(t, root, variant)
			args := []string{
				"-c", `tui.theme="8th-Light-` + variant + `"`,
				"-c", "check_for_update_on_startup=false",
				"-a", "on-request", "-s", "workspace-write",
			}
			terminal := launch(t, "codex", args, colors)
			if waitForAny(t, terminal, "trust", "Ask Codex") == "trust" {
				time.Sleep(time.Second)
				t.Log(screenText(t, terminal))
				t.Fatal("trust prompt not handled yet")
			}
			time.Sleep(2 * time.Second)
			typeSlowly(t, terminal, "/theme")
			time.Sleep(time.Second)
			typeKeys := func(sequence string) {
				if err := terminal.Type(sequence); err != nil {
					t.Fatal(err)
				}
			}
			typeKeys("\r")
			time.Sleep(2 * time.Second)
			t.Log(screenText(t, terminal))
			capture(t, terminal, colors, filepath.Join(directory, imageName(variant)))
		})
	}
}
