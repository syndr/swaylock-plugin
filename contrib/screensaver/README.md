# swaylock-screensaver — xscreensaver hacks as your lockscreen

Lock the session with a live [xscreensaver](https://www.jwz.org/xscreensaver/)
"hack" animating on every output, using `swaylock-plugin --command-each` +
[`windowtolayer`](https://gitlab.freedesktop.org/mstoeckl/windowtolayer) + the
packaged Xwayland wrapper. Includes a rofi picker with screenshot thumbnails
and per-hack descriptions, and a local thumbnail generator.

| script | role |
|---|---|
| `swaylock-screensaver` | lock launcher — reads the picked hack, degrades fail-safe |
| `swaylock-screensaver-select` | rofi picker — thumbnails, descriptions, live preview |
| `swaylock-screensaver-shots` | thumbnail generator — headless Xvfb + ImageMagick capture |

Packaged as **`swaylock-plugin-screensaver`** (RPM/COPR and Debian/Ubuntu
`.deb`), which installs the three scripts into `/usr/bin`. Or copy them from
this directory — they are self-contained.

## Dependencies

| | packages |
|---|---|
| required | `swaylock-plugin`, `windowtolayer`, Xwayland, `xkbcomp`, xscreensaver hacks (`xscreensaver-base` / `xscreensaver-extras` / GL sets; Debian: `xscreensaver`, `xscreensaver-data`) |
| picker | `rofi` (wayland build recommended), `libnotify` (`notify-send`) |
| thumbnails | `Xvfb` (Fedora: `xorg-x11-server-Xvfb`, Debian: `xvfb`), ImageMagick |

The hack directory is auto-detected (`/usr/libexec/xscreensaver`,
`/usr/lib/xscreensaver`, `/usr/lib64/misc/xscreensaver`); override with
`HACK_DIR`. See the main README's
[Xwayland-based plugins](../../README.md#xwayland-based-plugins) section for
the `/var/lib/xkb` requirement on some systems.

## Quick start

```sh
# pick a hack (opens rofi; Alt+p previews the highlighted hack live)
swaylock-screensaver-select

# lock now
swaylock-screensaver
```

Wire it into your idle daemon:

```
# swayidle (sway config)
exec swayidle -w \
    timeout 300 'swaylock-screensaver' \
    lock 'swaylock-screensaver' \
    before-sleep 'swaylock-screensaver'

# hypridle (hypridle.conf)
general {
    lock_cmd = swaylock-screensaver
}
```

The launcher is fail-safe: a lock trigger never leaves the session unlocked.
Degrade chain: picked hack → default hack (`xrayswarm`) → plain
`swaylock-plugin` → `$SWAYLOCK_SCREENSAVER_FALLBACK` (default `swaylock`) →
exit nonzero, so you can chain your own last resort with
`swaylock-screensaver || my-locker`.

**Recovery** if the locker misbehaves: switch to a TTY, log in,
`killall swaylock-plugin`, switch back. The session is still locked by
whatever your fallback is — fail-secure, not unlocked.

## Preview float rule

The picker's live preview opens the hack as a normal Xwayland window and waits
for you to close it before reopening. The X window class is per-hack
(`XRaySwarm`, ...), so float it by the stable title phrase:

```
# sway
for_window [title=".*from the XScreenSaver.*"] floating enable

# Hyprland (regexes full-match, hence the wildcards)
windowrule = match:title (.*from the XScreenSaver.*), float on, center on, size (monitor_w*0.5) (monitor_h*0.5)
```

## Per-hack options — `hacks.conf`

Most hacks take tuning flags (speed, density, count, ...). Set them in
`~/.config/swaylock-screensaver/hacks.conf`, one hack per line; a `*` line
applies to every hack (specific flags are appended after it, so they win):

```
# <hack> <extra args appended to the hack command>
glmatrix   --mode dna --speed 0.5
xrayswarm  --count 8
*          --fps            # applied to all hacks
```

Both the lockscreen and the picker's preview apply these, so previews match
what the lock will show. A trailing ` # comment` is stripped. Args pass
through one shell level — quote inside the value if an argument contains
spaces. Each hack documents its flags in `man <hack>` and in
`/usr/share/xscreensaver/config/<hack>.xml`.

A flag the hack does not accept makes it exit immediately: the session still
locks (fail-secure) but on a plain background instead of the animation. Test
flags with the picker's preview first — a hack that rejects your flags will
show no preview window.

## Thumbnails

`swaylock-screensaver-select` shows a screenshot per row once thumbnails
exist. They are generated **locally** — each hack runs briefly on a headless
Xvfb display and one frame is captured (jwz.org's gallery deliberately blocks
non-browser fetches, and local shots always match the installed versions).

The picker auto-starts generation in the background on first use (if Xvfb +
ImageMagick are present); ~290 hacks take about 10 minutes at the defaults.
Run manually or tune:

```sh
swaylock-screensaver-shots            # incremental: only missing shots
swaylock-screensaver-shots --force    # regenerate everything
SCREENHACK_SHOT_WARMUP=25 swaylock-screensaver-shots   # slow-starting hacks
```

A handful of hacks render black by design (webcollage needs network access,
vidwhacker a video source, ...) — they'd be equally blank as lock backgrounds.

## Environment knobs

| variable | default | used by |
|---|---|---|
| `HACK_DIR` | auto-detected (see above) | all |
| `HACK_STATE` | `$XDG_STATE_HOME/swaylock-screensaver/hack` | launcher, picker |
| `SWAYLOCK_SCREENSAVER_HACKS_CONF` | `$XDG_CONFIG_HOME/swaylock-screensaver/hacks.conf` | launcher, picker |
| `DEFAULT_HACK` | `xrayswarm` | launcher, picker |
| `WRAPPER` | `/usr/libexec/swaylock-plugin/example_xwayland_wrapper.py` | launcher |
| `SWAYLOCK_SCREENSAVER_FALLBACK` | `swaylock` | launcher |
| `SCREENHACK_ROFI_THEME` | *(rofi default config)* | picker |
| `SCREENHACK_PREVIEW_KEY` | `Alt+p` | picker |
| `SCREENHACK_XML_DIR` | `/usr/share/xscreensaver/config` | picker (descriptions) |
| `SCREENHACK_SHOT_DIR` | `$XDG_CACHE_HOME/swaylock-screensaver/shots` | picker, shots |
| `SCREENHACK_SHOT_WARMUP` | `8` (seconds) | shots |
| `SCREENHACK_SHOT_JOBS` | `4` | shots |
| `SCREENHACK_SHOT_SIZE` | `640x480` | shots |
| `SCREENHACK_SHOT_DISPLAY_BASE` | `90` (Xvfb `:90`+) | shots |

To see the thumbnails, the rofi theme you use must enable row icons, e.g.:

```rasi
element-icon { size: 88px; }
listview { columns: 1; }
```

## Provenance

Developed and verified in
[syndr/hyprland-wm-config](https://github.com/syndr/hyprland-wm-config) on a
4-output Hyprland workstation; extracted here as the canonical copy. MIT
licensed, matching this repository.
