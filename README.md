# Zinc Desktop

Zinc Desktop is an independent, source-first Linux desktop environment maintained by
[ZincGluxx](https://github.com/ZincGluxx). It is built from a Wayland and libcosmic-style desktop baseline and is being
actively rebranded, optimized, and extended into a personal desktop environment.

Zinc Desktop is not affiliated with or endorsed by any upstream vendor. See
[NOTICE.md](NOTICE.md) for upstream attribution and licensing.

## Development branch

The active development branch is:

```text
zinc/main
```

The initial baseline is pinned to the upstream 1.11 component commits. Source namespace
migration and desktop-identity rebranding are tracked as follow-up work on this branch.

## Components

### Session and system services

- [zinc-session](https://github.com/ZincGluxx/zinc-session)
- [zinc-comp](https://github.com/ZincGluxx/zinc-comp)
- [zinc-settings-daemon](https://github.com/ZincGluxx/zinc-settings-daemon)
- [zinc-idle](https://github.com/ZincGluxx/zinc-idle)
- [zinc-notifications](https://github.com/ZincGluxx/zinc-notifications)
- [zinc-osd](https://github.com/ZincGluxx/zinc-osd)
- [zinc-greeter](https://github.com/ZincGluxx/zinc-greeter)
- [xdg-desktop-portal-zinc](https://github.com/ZincGluxx/xdg-desktop-portal-zinc)

### Shell, panel, and launcher

- [zinc-panel](https://github.com/ZincGluxx/zinc-panel)
- [zinc-applets](https://github.com/ZincGluxx/zinc-applets)
- [zinc-app-library](https://github.com/ZincGluxx/zinc-app-library)
- [zinc-launcher](https://github.com/ZincGluxx/zinc-launcher)
- [zinc-workspaces](https://github.com/ZincGluxx/zinc-workspaces)
- [zinc-pop-launcher](https://github.com/ZincGluxx/zinc-pop-launcher)
- [zinc-bg](https://github.com/ZincGluxx/zinc-bg)
- [zinc-osk](https://github.com/ZincGluxx/zinc-osk)

### Applications and tools

- [zinc-files](https://github.com/ZincGluxx/zinc-files)
- [zinc-edit](https://github.com/ZincGluxx/zinc-edit)
- [zinc-term](https://github.com/ZincGluxx/zinc-term)
- [zinc-store](https://github.com/ZincGluxx/zinc-store)
- [zinc-settings](https://github.com/ZincGluxx/zinc-settings)
- [zinc-viewer](https://github.com/ZincGluxx/zinc-viewer)
- [zinc-player](https://github.com/ZincGluxx/zinc-player)
- [zinc-initial-setup](https://github.com/ZincGluxx/zinc-initial-setup)
- [zinc-screenshot](https://github.com/ZincGluxx/zinc-screenshot)
- [zinc-randr](https://github.com/ZincGluxx/zinc-randr)
- [zinc-monitor](https://github.com/ZincGluxx/zinc-monitor)

### Toolkits and shared libraries

- [libzinc](https://github.com/ZincGluxx/libzinc)
- [zinc-text](https://github.com/ZincGluxx/zinc-text)
- [zinc-theme](https://github.com/ZincGluxx/zinc-theme)
- [zinc-time](https://github.com/ZincGluxx/zinc-time)
- [zinc-protocols](https://github.com/ZincGluxx/zinc-protocols)

### Resources

- [zinc-icons](https://github.com/ZincGluxx/zinc-icons)
- [zinc-sound-theme](https://github.com/ZincGluxx/zinc-sound-theme)
- [zinc-wallpapers](https://github.com/ZincGluxx/zinc-wallpapers)

## Build

The project is intended to build as a multi-repository desktop tree. Until packaging
is stabilized, build on Arch Linux from the repository root:

```bash
git clone --recurse-submodules git@github.com:ZincGluxx/zinc-desktop.git
cd zinc-desktop
just build
```

Build dependencies follow the upstream Wayland/Rust stack, including Rust, just,
meson, wayland, libinput, libxkbcommon, mesa, pipewire, and fontconfig.

## Repository layout

Each submodule is an independent repository under
[ZincGluxx](https://github.com/ZincGluxx). The root repository owns integration,
build orchestration, release metadata, and cross-component policy.

## License

Zinc Desktop is distributed under the licenses of its component repositories.
Most components are GPL-3.0-only or MPL-2.0. See each repository's `LICENSE` file
and [NOTICE.md](NOTICE.md) for details.
