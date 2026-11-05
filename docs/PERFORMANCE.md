# Performance work log

## First priority batch

### zinc-session

- App library, launcher, and workspaces are no longer eagerly preloaded.
  They start on demand from their normal desktop entries or global actions.
- `ZINC_PRELOAD_LAUNCHERS=1` restores eager preloading for users who prefer
  instant first-open behavior.
- Independent components start concurrently after the notifications/panel
  socket handshake.
- Systemd manager calls reuse one session-bus connection; environment and
  target updates use the manager proxy instead of spawning `systemctl`.

### zinc-files

- The compio runtime and its dedicated worker thread are created on the first
  operation that needs asynchronous file I/O.
- Nav-model construction no longer forces the mounter registry during
  `App::init`. GVfs itself remains connected at subscription time because
  deferring it further would risk losing mount hotplug events; the constraint
  is documented in `docs/gvfs-lazy-init.md`.

### zinc-term

- Unchanged terminal rows no longer clone text and attribute lists before
  equality checks.
- Selection and cursor state are computed once per update rather than per cell.
- URL match post-processing avoids one temporary `Vec` per match.
- The shape-run cache is trimmed only when rows actually changed.
- Added focused tests for the BufferLine update helper.

### zinc-bg

- The full-resolution decoded wallpaper is released after output-sized buffers
  have been produced, and glibc arenas are trimmed. The image is re-decoded
  only on a future actual redraw.

## Validation

- `zinc-session`: `cargo check --all-targets`, `--all-features`,
  `--no-default-features`, and tests for both feature sets pass.
- `zinc-files`: `cargo check --all-targets` passes; lazy-init and mounter tests
  pass.
- `zinc-term`: `cargo check --all-targets` passes; 15 tests pass.
- `zinc-bg`: `cargo check --all-targets` passes.
- `zinc-bg` and session commit checks use the project Rust 1.93 toolchain;
  build artifacts share `/home/zincg/.cache/zinc-target`.

## Still open

- Panel/applet process consolidation is architectural: 34 applet processes are
  created for two panel profiles across two outputs. Native panel buttons,
  shared applet hosting, or primary-only applet policy need separate design
  and runtime validation.
- Compositor scene traversal and blur work need controlled Tracy/frame-time
  measurements before changing render scheduling or caches.
- Live A/B memory and startup measurements require building and launching the
  new session in a nested or test login session.
