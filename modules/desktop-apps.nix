{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.desktopApps;

  # Build a bubblewrap sandbox wrapper for a desktop application.
  # This helper is informed by AppArmor desktop profiles (firefox, chromium,
  # etc.) and translates their filesystem/network access patterns into pure-Nix
  # bwrap sandbox binds.
  makeBwrapWrapper =
    { pkg
    , name ? pkg.pname or pkg.name
    , binName ? name
    , homeDir ? ".config/${name}"
    , extraReadOnlyPaths ? []
    , extraReadWritePaths ? []
    , allowNetwork ? true
    , allowGpu ? true
    , allowWayland ? true
    , allowX11 ? true
    , allowDbus ? true
    , allowPipewire ? true
    , allowPulse ? true
    , allowUdev ? true
    , sandboxHome ? false  # if true, create an isolated tmpfs home
    }:
    pkgs.runCommandLocal "${name}-sandboxed" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = binName;
    } ''
      mkdir -p $out/bin
      cat > $out/bin/${binName} <<'WRAPPER'
      #!/bin/sh
      set -e

      # Bubblewrap argument accumulator (NixOS /bin/sh is bash)
      args=()
      args+=(--unshare-all)
      ${if allowNetwork then "args+=(--share-net)" else ""}
      args+=(--die-with-parent)
      args+=(--new-session)
      args+=(--proc /proc)
      args+=(--dev /dev)
      args+=(--tmpfs /tmp)
      args+=(--ro-bind /nix /nix)
      args+=(--ro-bind /run /run)
      args+=(--ro-bind /etc /etc)

      # Wayland display socket
      ${if allowWayland then ''
        if [ -n "$WAYLAND_DISPLAY" ] && [ -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY")
        fi
      '' else ""}

      # X11 Unix domain sockets
      ${if allowX11 then ''
        if [ -d /tmp/.X11-unix ]; then
          args+=(--ro-bind /tmp/.X11-unix /tmp/.X11-unix)
        fi
        if [ -n "$DISPLAY" ]; then
          # Pass through DISPLAY so the app knows which X server to use
          args+=(--setenv DISPLAY "$DISPLAY")
        fi
      '' else ""}

      # D-Bus session bus
      ${if allowDbus then ''
        if [ -e "$XDG_RUNTIME_DIR/bus" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus")
        fi
        if [ -e /run/dbus/system_bus_socket ]; then
          args+=(--ro-bind /run/dbus/system_bus_socket /run/dbus/system_bus_socket)
        fi
      '' else ""}

      # PipeWire
      ${if allowPipewire then ''
        if [ -e "$XDG_RUNTIME_DIR/pipewire-0" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0")
        fi
        if [ -d "$XDG_RUNTIME_DIR/pipewire" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/pipewire" "$XDG_RUNTIME_DIR/pipewire")
        fi
      '' else ""}

      # PulseAudio (legacy, often symlinked to PipeWire)
      ${if allowPulse then ''
        if [ -e "$XDG_RUNTIME_DIR/pulse" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse")
        fi
        if [ -e "$XDG_RUNTIME_DIR/pulse/native" ]; then
          args+=(--ro-bind "$XDG_RUNTIME_DIR/pulse/native" "$XDG_RUNTIME_DIR/pulse/native")
        fi
      '' else ""}

      # GPU devices (DRI)
      ${if allowGpu then ''
        if [ -d /dev/dri ]; then
          args+=(--dev-bind /dev/dri /dev/dri)
        fi
        if [ -e /dev/kfd ]; then
          args+=(--dev-bind /dev/kfd /dev/kfd)
        fi
        for nvid in /dev/nvidia*; do
          if [ -e "$nvid" ]; then
            args+=(--dev-bind "$nvid" "$nvid")
          fi
        done
      '' else ""}

      # udev data for GPU enumeration and device IDs
      ${if allowUdev then ''
        if [ -d /run/udev ]; then
          args+=(--ro-bind /run/udev /run/udev)
        fi
      '' else ""}

      # Fonts (system + user)
      args+=(--ro-bind /run/current-system/sw/share/fonts /run/current-system/sw/share/fonts)
      if [ -d "$HOME/.local/share/fonts" ]; then
        args+=(--ro-bind "$HOME/.local/share/fonts" "$HOME/.local/share/fonts")
      fi
      if [ -d "$HOME/.fonts" ]; then
        args+=(--ro-bind "$HOME/.fonts" "$HOME/.fonts")
      fi

      # Icons and themes
      args+=(--ro-bind /run/current-system/sw/share/icons /run/current-system/sw/share/icons)
      args+=(--ro-bind /run/current-system/sw/share/themes /run/current-system/sw/share/themes)

      # GLib schemas (GSettings)
      args+=(--ro-bind /run/current-system/sw/share/glib-2.0 /run/current-system/sw/share/glib-2.0)

      # Locale
      args+=(--ro-bind /run/current-system/sw/share/locale /run/current-system/sw/share/locale)
      if [ -e /etc/locale.conf ]; then
        args+=(--ro-bind /etc/locale.conf /etc/locale.conf)
      fi

      # Timezone
      if [ -e /etc/localtime ]; then
        args+=(--ro-bind /etc/localtime /etc/localtime)
      fi

      # Machine ID (some apps need it)
      if [ -e /etc/machine-id ]; then
        args+=(--ro-bind /etc/machine-id /etc/machine-id)
      fi

      # Home directory handling
      ${if sandboxHome then ''
        # Create a fresh tmpfs home with only allowed subdirs
        args+=(--tmpfs "$HOME")
        args+=(--bind "$HOME/Downloads" "$HOME/Downloads")
        if [ -d "$HOME/${homeDir}" ]; then
          args+=(--bind "$HOME/${homeDir}" "$HOME/${homeDir}")
        fi
      '' else ''
        # Bind the app-specific config dir read-write
        if [ -d "$HOME/${homeDir}" ]; then
          args+=(--bind "$HOME/${homeDir}" "$HOME/${homeDir}")
        else
          args+=(--dir "$HOME/${homeDir}")
        fi
        # Downloads are always available
        if [ -d "$HOME/Downloads" ]; then
          args+=(--bind "$HOME/Downloads" "$HOME/Downloads")
        fi
      ''}

      # Extra user-supplied paths
      ${lib.concatMapStringsSep "\n" (p: "args+=(--ro-bind \"${p}\" \"${p}\")") extraReadOnlyPaths}
      ${lib.concatMapStringsSep "\n" (p: "args+=(--bind \"${p}\" \"${p}\")") extraReadWritePaths}

      # Environment passthrough
      args+=(--setenv HOME "$HOME")
      args+=(--setenv USER "$USER")
      args+=(--setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR")
      args+=(--setenv XDG_SESSION_TYPE "$XDG_SESSION_TYPE")
      args+=(--setenv XDG_CURRENT_DESKTOP "$XDG_CURRENT_DESKTOP")
      args+=(--setenv PATH "/run/current-system/sw/bin")

      # Execute the target binary
      exec ${pkgs.bubblewrap}/bin/bwrap "''${args[@]}" -- "${pkg}/bin/${binName}" "$@"
      WRAPPER
      chmod +x $out/bin/${binName}
    '';
in
{
  options.hardening.desktopApps = {
    enable = mkEnableOption "desktop application sandboxing via bubblewrap";

    firefox = {
      enable = mkEnableOption "sandboxed Firefox wrapper" // { default = cfg.enable; };
    };

    chromium = {
      enable = mkEnableOption "sandboxed Chromium wrapper" // { default = cfg.enable; };
    };

    thunderbird = {
      enable = mkEnableOption "sandboxed Thunderbird wrapper" // { default = cfg.enable; };
    };

    discord = {
      enable = mkEnableOption "sandboxed Discord wrapper" // { default = cfg.enable; };
    };

    signal = {
      enable = mkEnableOption "sandboxed Signal Desktop wrapper" // { default = cfg.enable; };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      lib.optional cfg.firefox.enable (
        makeBwrapWrapper {
          pkg = pkgs.firefox;
          homeDir = ".mozilla";
          extraReadWritePaths = [ "$HOME/Downloads" ];
        }
      )
      ++ lib.optional cfg.chromium.enable (
        makeBwrapWrapper {
          pkg = pkgs.chromium;
          homeDir = ".config/chromium";
          extraReadWritePaths = [ "$HOME/Downloads" ];
        }
      )
      ++ lib.optional cfg.thunderbird.enable (
        makeBwrapWrapper {
          pkg = pkgs.thunderbird;
          homeDir = ".thunderbird";
          extraReadWritePaths = [ "$HOME/Downloads" ];
        }
      )
      ++ lib.optional cfg.discord.enable (
        makeBwrapWrapper {
          pkg = pkgs.discord;
          homeDir = ".config/discord";
          extraReadWritePaths = [ "$HOME/Downloads" ];
          # Discord updates itself; needs broader access or use web version
          sandboxHome = false;
        }
      )
      ++ lib.optional cfg.signal.enable (
        makeBwrapWrapper {
          pkg = pkgs.signal-desktop;
          homeDir = ".config/Signal";
          extraReadWritePaths = [ "$HOME/Downloads" ];
        }
      );
  };
}
