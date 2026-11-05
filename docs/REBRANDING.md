# Zinc Desktop rebranding status

## Product identity

| Item | Value |
|---|---|
| Product name | Zinc Desktop |
| Repository root | `ZincGluxx/zinc-desktop` |
| Development branch | `zinc/main` |
| Component repos | `zinc-*` under `ZincGluxx` |
| Toolkit repo | `libzinc` |
| Toolkit Rust library | `zinc` |
| App ID / D-Bus namespace | `com.zincgluxx.*` |
| Environment variable prefix | `ZINC_*` |

## Completed

- All 31 desktop-tree repositories plus the five core libraries are forked under
  `ZincGluxx`.
- GitHub repositories were renamed to the `zinc-*` naming scheme.
- Every repository has a `zinc/main` development branch and the default branch now
  points at `zinc/main`.
- The integration repository was rebuilt with renamed submodule paths and URLs.
- The new integration tree is available at `/home/zincg/zinc-desktop` with all 30
  component submodules checked out and a local `zinc/main` branch.
- Local `origin` remotes point at Zinc forks; `upstream` remotes point at the
  corresponding upstream repositories for reference and future synchronization.
- Root README, repository map, issue templates, CI checkout settings, and release
  tag helper are rebranded.
- Upstream copyright and license attribution is preserved in `NOTICE.md`.

## Source-level migration phases

The source baseline is intentionally left buildable while the public identity is
changed incrementally. The following migrations should be completed on dedicated
feature branches and validated per component:

1. Binary and desktop-entry names: `zinc-*` executables, desktop files, icons,
   systemd units, and session component launch names.
2. Application and D-Bus namespace: `com.zincgluxx.*` app IDs, bus names, portal
   implementation names, config directories, and migration of existing user config.
3. Runtime variables and theme keys: `ZINC_*` environment variables, `Zinc Dark` /
   `Zinc Light` theme names, asset paths, and locale strings.
4. Crate and package namespace: `zinc-*` Cargo packages, shared library imports,
   dependency URLs, lockfile regeneration, and upstream support-library patches.
5. Branding assets: new logo, icon theme, boot/session artwork, sound theme, and
   wallpaper collection.

## Rules

- Do not remove or rewrite upstream copyright and license headers.
- Do not mix source-level migration with performance work in the same commit.
- Every component migration must include a build or `cargo check` in its own CI job.
- Keep `upstream` remotes configured; upstream fixes should remain mergeable.
