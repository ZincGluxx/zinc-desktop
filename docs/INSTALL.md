# Building and installing Zinc Desktop

## Build status

The full release tree has been built successfully from `/home/zincg/zinc-desktop`
with the project Rust toolchain. The only local non-system build tool used was a
locally extracted `nasm` under `~/.cache/zinc-deps`, needed by `turbojpeg-sys`.

A staging install of the full tree completed successfully (1,314 files, about
1.2 GiB), including binaries, desktop entries, icons, portal data, the
`zinc-session` launcher and the `zinc.desktop` wayland session entry.

## Install from already-built artifacts

Run from a TTY as the desktop user (not with sudo):

```sh
cd /home/zincg/zinc-desktop
./scripts/install-zinc.sh --install-only
```

Type `INSTALL` at the prompt. The installer:

- stages the already-built release artifacts under `/usr/local`
- installs `/usr/local/bin/zinc-session`
- installs `/usr/local/share/wayland-sessions/zinc.desktop`
- backs up `/usr/local`
- writes a manifest and rollback script

Then switch sessions:

```sh
sudo systemctl restart cosmic-greeter
```

Select **Zinc Desktop** on the login screen.

## Rebuild from source

```sh
cd /home/zincg/zinc-desktop
PATH="$HOME/.cache/zinc-deps/usr/bin:$HOME/.cargo/bin:$PATH" \
  CARGO_BUILD_JOBS=16 just build
```

Or let the installer build and install in one step:

```sh
./scripts/install-zinc.sh --full
```

`meson`, `ninja`, and `git-lfs` are optional locally; absent packages only skip
the sound-theme build and LFS asset refresh.

## Rollback

The installer prints the rollback path, for example:

```sh
sudo /home/zincg/zinc-install-backups/<timestamp>/rollback.sh
```

The original `/usr` packages are never overwritten; choosing the original
COSMIC session at the greeter remains the fallback.

## Internal naming note

User-facing branding and UI strings are Zinc. Several internal binary, D-Bus and
config identifiers still use upstream-compatible names pending the staged
namespace migration described in `docs/REBRANDING.md`.

## If login returns to the greeter

A failed login can leave an old compositor holding DRM master, causing the next
`cosmic-comp` to start in unprivileged mode. Reboot to guarantee a clean DRM
state:

```sh
sudo systemctl reboot
```

At the login screen select **Zinc Desktop**. Do not restart only `greetd.service`
on this system; the active display manager is `cosmic-greeter.service`.

If it still fails after reboot, collect:

```sh
journalctl -b -u cosmic-greeter --no-pager | tail -100
journalctl -b --no-pager | grep -Ei 'cosmic-comp|drm master|failed to submit|failed to render' | tail -100
```

## Hybrid-GPU compositor fallback

The locally built `cosmic-comp` from the current fork revision cannot acquire
DRM master on this hybrid Intel/NVIDIA system, including for the greeter. Use
the system compositor while keeping the rest of Zinc local:

```sh
cd /home/zincg/zinc-desktop
./scripts/install-zinc.sh --install-only --system-compositor
```

This installs a symlink at `/usr/local/bin/cosmic-comp` pointing to
`/usr/bin/cosmic-comp`. Reboot afterward:

```sh
sudo systemctl reboot
```

Verify the clean boot with:

```sh
journalctl -b --no-pager | grep 'Unable to become drm master' || true
```
