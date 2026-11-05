#!/usr/bin/env bash
# Build and stage-install Zinc Desktop from /usr/local without touching /usr.
# Run as the desktop user (not root) from a TTY; sudo is used for installation.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${ZINC_PREFIX:-/usr/local}"
MODE="full"
INSTALL_DEPS=0
ASSUME_YES=0
RESTART_GREETER=0
SKIP_LFS=0

usage() {
    cat <<USAGE
Usage: $0 [options]

Build Zinc Desktop from $ROOT, install it under $PREFIX, and add a
"Zinc Desktop" session entry. Run this as the desktop user from a TTY.
Do NOT run it from inside the graphical session you are replacing.

Options:
  --full             Build all components (default)
  --quick            Build only the components changed in the first pass:
                     zinc-session, zinc-term, zinc-files, zinc-bg, zinc-panel
  --install-deps     Install build dependencies with pacman first
  --skip-lfs         Do not attempt to fetch Git LFS wallpaper/icon assets
  --restart-greeter  Restart greetd after installation (kills the graphical session)
  --yes              Skip the final confirmation prompt
  -h, --help         Show this help

Environment:
  ZINC_PREFIX        Install prefix, default: /usr/local

Examples:
  ./scripts/install-zinc.sh --full --install-deps
  ./scripts/install-zinc.sh --quick --yes
USAGE
}

while (($#)); do
    case "$1" in
        --full) MODE="full" ;;
        --quick) MODE="quick" ;;
        --install-deps) INSTALL_DEPS=1 ;;
        --skip-lfs) SKIP_LFS=1 ;;
        --restart-greeter) RESTART_GREETER=1 ;;
        --yes) ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ ${EUID} -eq 0 ]]; then
    echo "Run this as the desktop user, not as root. The script calls sudo where needed." >&2
    exit 1
fi

export PATH="$HOME/.cargo/bin:$PATH"
if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required" >&2
    exit 1
fi

missing=()
for cmd in git cargo rustc just sudo rsync; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ "$MODE" == "full" ]]; then
    for cmd in meson ninja git-lfs; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
fi

PKGS=(
    base-devel cmake clang desktop-file-utils git git-lfs gtk3 gtk4 just
    libdisplay-info libinput libxkbcommon llvm lld mesa meson ninja
    pipewire pulseaudio seatd wayland wayland-protocols expat fontconfig
    freetype2 flatpak nasm rsync
)
if ((${#missing[@]})); then
    echo "Missing required commands: ${missing[*]}"
    if ((INSTALL_DEPS)); then
        echo "Installing build dependencies with pacman..."
        sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    else
        echo "Install dependencies and retry, or run with --install-deps." >&2
        exit 1
    fi
elif ((INSTALL_DEPS)); then
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
fi

if [[ "$(git -C "$ROOT" branch --show-current)" != "zinc/main" ]]; then
    echo "Expected branch zinc/main in $ROOT" >&2
    exit 1
fi
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    echo "Integration tree is dirty. Commit/stash changes before installing." >&2
    git -C "$ROOT" status --short >&2
    exit 1
fi
while read -r path; do
    if [[ -n "$(git -C "$ROOT/$path" status --porcelain)" ]]; then
        echo "Submodule $path is dirty; refusing to build an unreproducible tree." >&2
        git -C "$ROOT/$path" status --short >&2
        exit 1
    fi
done < <(git -C "$ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/zinc-install.$STAMP.XXXXXX")"
STAGE="$WORK/stage"
BACKUP="$HOME/zinc-install-backups/$STAMP"
mkdir -p "$STAGE" "$BACKUP" "$WORK/logs"
cleanup() {
    if [[ -d "$WORK/logs" ]]; then
        mkdir -p "$BACKUP"
        cp -a "$WORK/logs" "$BACKUP/logs" 2>/dev/null || true
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

if ((!SKIP_LFS)) && command -v git-lfs >/dev/null 2>&1; then
    echo "Fetching Git LFS assets..."
    for repo in zinc-wallpapers zinc-icons zinc-screenshot; do
        if [[ -d "$ROOT/$repo" ]]; then
            git -C "$ROOT/$repo" lfs install --local >/dev/null 2>&1 || true
            git -C "$ROOT/$repo" lfs pull >/dev/null 2>&1 || \
                echo "warning: git lfs pull failed for $repo" >&2
        fi
    done
fi
if find "$ROOT/zinc-wallpapers/original" -type f -name '*.jpg' -size -1k 2>/dev/null | grep -q .; then
    echo "warning: some wallpapers are still Git LFS pointer files" >&2
fi

echo "Building Zinc Desktop ($MODE mode); logs: $WORK/logs"
if [[ "$MODE" == "full" ]]; then
    (cd "$ROOT" && just build) 2>&1 | tee "$WORK/logs/build.log"
    echo "Staging full install under $STAGE$PREFIX"
    (cd "$ROOT" && just install rootdir="$STAGE" prefix="$PREFIX") 2>&1 | tee "$WORK/logs/install-stage.log"

    echo "Building and staging sound theme..."
    meson setup "$WORK/sound-build" "$ROOT/zinc-sound-theme" \
        --prefix="$PREFIX" --buildtype=release >/dev/null
    meson compile -C "$WORK/sound-build" 2>&1 | tee "$WORK/logs/sound-build.log"
    DESTDIR="$STAGE" meson install -C "$WORK/sound-build" 2>&1 | tee "$WORK/logs/sound-install.log"
else
    for component in zinc-session zinc-term zinc-files zinc-bg zinc-panel; do
        echo "Building $component"
        (cd "$ROOT/$component" && just build-release) 2>&1 | tee "$WORK/logs/$component.log"
        echo "Staging $component"
        (cd "$ROOT/$component" && just rootdir="$STAGE" prefix="$PREFIX" install) \
            2>&1 | tee -a "$WORK/logs/$component.log"
    done
fi

SESSION_DESKTOP="$STAGE$PREFIX/share/wayland-sessions/zinc.desktop"
if [[ -f "$SESSION_DESKTOP" ]]; then
    sed -i "s|^Exec=zinc-session$|Exec=$PREFIX/bin/zinc-session|; s|^TryExec=zinc-session$|TryExec=$PREFIX/bin/zinc-session|" "$SESSION_DESKTOP"
else
    echo "warning: session desktop file was not staged" >&2
fi

if [[ ! -x "$STAGE$PREFIX/bin/cosmic-session" ]]; then
    echo "error: staged cosmic-session binary is missing" >&2
    exit 1
fi
if [[ ! -x "$STAGE$PREFIX/bin/zinc-session" ]]; then
    echo "error: staged zinc-session launcher is missing" >&2
    exit 1
fi

echo "Preparing installation manifest and backup..."
(cd "$STAGE" && find . -mindepth 1 \( -type f -o -type l \) -printf '%P\n' | sort) > "$WORK/manifest.txt"
cp "$WORK/manifest.txt" "$BACKUP/manifest.txt"
if [[ -d /usr/local ]]; then
    sudo tar -C / -czf "$BACKUP/usr-local.tar.gz" usr/local
fi

echo
echo "This will install files under $PREFIX and add a Zinc Desktop session."
if ((!ASSUME_YES)); then
    read -r -p "Type INSTALL to continue: " answer
    [[ "$answer" == "INSTALL" ]] || { echo "Aborted."; exit 1; }
fi

echo "Installing staged files..."
sudo rsync -a --chown=root:root "$STAGE/" /
sudo install -Dm0644 "$WORK/manifest.txt" "$PREFIX/share/zinc/install-manifest.txt"

cat > "$BACKUP/rollback.sh" <<ROLLBACK
#!/usr/bin/env bash
set -euo pipefail
while IFS= read -r rel; do
    sudo rm -f "/\$rel"
done < "$BACKUP/manifest.txt"
if [[ -f "$BACKUP/usr-local.tar.gz" ]]; then
    sudo tar -C / -xzf "$BACKUP/usr-local.tar.gz"
fi
sudo systemctl restart greetd 2>/dev/null || true
echo "Rolled back Zinc Desktop installation."
ROLLBACK
chmod 0755 "$BACKUP/rollback.sh"

if command -v update-desktop-database >/dev/null 2>&1; then
    sudo update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true
fi

echo
echo "Zinc Desktop installed under $PREFIX."
echo "Manifest: $PREFIX/share/zinc/install-manifest.txt"
echo "Rollback: $BACKUP/rollback.sh"
echo "Logs: $WORK/logs (copied below before cleanup)"
cp -a "$WORK/logs" "$BACKUP/logs"
echo "Log backup: $BACKUP/logs"

if ((RESTART_GREETER)); then
    sudo systemctl restart greetd
else
    echo
    echo "Log out, switch to a TTY if needed, then run:"
    echo "  sudo systemctl restart greetd"
    echo "Select 'Zinc Desktop' at the login screen."
fi
