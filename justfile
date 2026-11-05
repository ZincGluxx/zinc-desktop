set dotenv-load
just := just_executable()
make := `which make`

build:
    mkdir -p build
    {{ just }} zinc-applets/build-release
    cd zinc-app-library && {{ just }} build-release
    {{ just }} zinc-bg/build-release
    {{ just }} zinc-comp/build-release
    {{ just }} zinc-edit/build-release
    {{ just }} zinc-files/build-release
    {{ just }} zinc-greeter/build-release
    {{ just }} zinc-idle/build-release
    cd zinc-initial-setup && {{ just }} build-release
    cd zinc-launcher && {{ just }} build-release
    {{ just }} zinc-monitor/build-release
    {{ just }} zinc-notifications/build-release
    {{ just }} zinc-osd/build-release
    {{ just }} zinc-osk/build-release
    {{ just }} zinc-panel/build-release
    {{ just }} zinc-player/build-release
    {{ just }} zinc-randr/build-release
    {{ just }} zinc-screenshot/build-release
    cd zinc-settings && {{ just }} build-release
    cd zinc-settings-daemon && {{ just }} build-release
    {{ just }} zinc-session/build-release
    {{ just }} zinc-store/build-release
    {{ just }} zinc-term/build-release
    {{ just }} zinc-viewer/build-release
    {{ make }} -C zinc-wallpapers all
    {{ make }} -C zinc-workspaces all
    {{ just }} zinc-pop-launcher/build-release
    cd xdg-desktop-portal-zinc && {{ just }} debug=0

install rootdir="" prefix="/usr/local": build
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-applets/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-app-library/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-bg/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-comp/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-edit/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-files/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-greeter/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-icons/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-idle/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-initial-setup/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-launcher/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-monitor/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-notifications/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-osd/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-osk/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-panel/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-player/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-randr/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-screenshot/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-settings/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-settings-daemon/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-session/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-store/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-term/install
    {{ just }} rootdir={{rootdir}} prefix={{prefix}} zinc-viewer/install
    {{ make }} -C zinc-wallpapers install DESTDIR={{rootdir}} prefix={{prefix}}
    {{ make }} -C zinc-workspaces install DESTDIR={{rootdir}} prefix={{prefix}}
    {{ just }} rootdir={{rootdir}} zinc-pop-launcher/install
    cd xdg-desktop-portal-zinc && {{ just }} rootdir={{rootdir}} prefix={{prefix}} install

_mkdir dir:
   mkdir -p dir

sysext dir=(invocation_directory() / "zinc-sysext") version=("nightly-" + `git rev-parse --short HEAD`): (_mkdir dir) (install dir "/usr")
    #!/usr/bin/env sh
    mkdir -p {{dir}}/usr/lib/extension-release.d/
    cat >{{dir}}/usr/lib/extension-release.d/extension-release.zinc-sysext <<EOF
    NAME="Zinc DE"
    VERSION={{version}}
    $(cat /etc/os-release | grep '^ID=')
    $(cat /etc/os-release | grep '^VERSION_ID=')
    EOF
    echo "Done"

clean:
    rm -rf zinc-sysext
    rm -rf zinc-applets/target
    rm -rf zinc-app-library/target
    rm -rf zinc-bg/target
    rm -rf zinc-comp/target
    rm -rf zinc-edit/target
    {{ just }} zinc-files/clean
    rm -rf zinc-greeter/target
    {{ just }} zinc-idle/clean
    cd zinc-initial-setup && {{ just }} clean
    rm -rf zinc-launcher/target
    {{ just }} zinc-monitor/clean
    rm -rf zinc-panel/target
    rm -rf zinc-player/target
    rm -rf zinc-notifications/target
    rm -rf zinc-osd/target
    rm -rf zinc-osk/target
    rm -rf zinc-randr/target
    rm -rf zinc-screenshot/target
    rm -rf zinc-settings/target
    rm -rf zinc-settings-daemon/target
    rm -rf zinc-session/target
    {{ just }} zinc-store/clean
    {{ just }} zinc-term/clean
    {{ just }} zinc-viewer/clean
    {{ make }} -C zinc-wallpapers clean
    rm -rf zinc-workspaces/target
    {{ just }} zinc-pop-launcher/clean
    rm -rf xdg-desktop-portal-zinc/target
