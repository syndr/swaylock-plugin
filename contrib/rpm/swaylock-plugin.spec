%{!?pkg_version:%global pkg_version 1.8.6.2}

Name:           swaylock-plugin
Version:        %{pkg_version}
Release:        %{?pkg_release}%{!?pkg_release:1}.syndr%{?dist}
Summary:        Screen locker with plugin support for Wayland compositors

License:        MIT
URL:            https://github.com/syndr/swaylock-plugin
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  pam-devel
BuildRequires:  scdoc
BuildRequires:  pkgconfig(cairo)
BuildRequires:  pkgconfig(gdk-pixbuf-2.0)
BuildRequires:  pkgconfig(libsystemd)
BuildRequires:  pkgconfig(wayland-client) >= 1.20.0
BuildRequires:  pkgconfig(wayland-protocols) >= 1.47
BuildRequires:  pkgconfig(wayland-scanner) >= 1.15.0
BuildRequires:  pkgconfig(wayland-server) >= 1.20.0
BuildRequires:  pkgconfig(xkbcommon)

Requires:       python3

%description
swaylock-plugin is a Wayland screen locker derived from swaylock that can run
plugin commands as lockscreen backgrounds.

%package screensaver
Summary:        Xscreensaver hack lockscreen tooling for swaylock-plugin
Requires:       %{name} = %{version}-%{release}
Requires:       windowtolayer
Recommends:     rofi
Recommends:     xscreensaver-base
Suggests:       xorg-x11-server-Xvfb
Suggests:       ImageMagick

%description screensaver
Lock the session with a live xscreensaver "hack" animating on every output.
Ships swaylock-screensaver (fail-safe lock launcher), swaylock-screensaver-select
(rofi picker with screenshot thumbnails, per-hack descriptions, and live
preview), and swaylock-screensaver-shots (local thumbnail generator using a
headless Xvfb display).

%prep
%autosetup -n %{name}-%{version}

%build
%meson \
    -Dpam=enabled \
    -Dlogind=enabled \
    -Dgdk-pixbuf=enabled \
    -Dman-pages=enabled
%meson_build

%install
%meson_install
install -Dpm0755 example_xwayland_wrapper.py \
    %{buildroot}%{_libexecdir}/%{name}/example_xwayland_wrapper.py
install -Dpm0755 contrib/screensaver/swaylock-screensaver \
    %{buildroot}%{_bindir}/swaylock-screensaver
install -Dpm0755 contrib/screensaver/swaylock-screensaver-select \
    %{buildroot}%{_bindir}/swaylock-screensaver-select
install -Dpm0755 contrib/screensaver/swaylock-screensaver-shots \
    %{buildroot}%{_bindir}/swaylock-screensaver-shots

%files
%license LICENSE
%{_bindir}/swaylock-plugin
%{_bindir}/swaylock-sleep-watcher
%{_libexecdir}/%{name}/example_xwayland_wrapper.py
%{_mandir}/man1/swaylock-plugin.1*
%{_datadir}/bash-completion/completions/swaylock-plugin
%{_datadir}/fish/vendor_completions.d/swaylock-plugin.fish
%{_datadir}/zsh/site-functions/_swaylock-plugin
%config(noreplace) %{_sysconfdir}/pam.d/swaylock-plugin

%files screensaver
%license LICENSE
%doc contrib/screensaver/README.md
%{_bindir}/swaylock-screensaver
%{_bindir}/swaylock-screensaver-select
%{_bindir}/swaylock-screensaver-shots

%changelog
* Mon Jul 06 2026 syndr <syndr@ultroncore.net> - 1.8.6.2-1
- Add the swaylock-plugin-screensaver subpackage: xscreensaver hack lock
  launcher, rofi picker with thumbnails/descriptions, and local thumbnail
  generator (contrib/screensaver)

* Sat Jul 04 2026 syndr <syndr@ultroncore.net> - 1.8.6.1-1
- First fork release; version distinguished from upstream 1.8.6 (v1.8.6 is an
  upstream tag). RPMs carry the .syndr Release marker.

* Thu Jul 02 2026 syndr <syndr@ultroncore.net> - 1.8.6-1
- Initial COPR package for the syndr swaylock-plugin fork
