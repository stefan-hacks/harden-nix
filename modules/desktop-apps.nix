{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.desktopApps;

  # Helper: wrap a package in a minimal bubblewrap sandbox.
  # This is a starting point; real desktop apps need additional binds
  # for Wayland, X11, GPU, D-Bus, PipeWire, etc.
  makeBwrapWrapper = { pkg, name ? pkg.pname or pkg.name, extraBinds ? [] }:
    pkgs.runCommandLocal "${name}-sandboxed" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = name;
    } ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/${name} \
        --add-flags "--unshare-all" \
        --add-flags "--share-net" \
        --add-flags "--die-with-parent" \
        --add-flags "--new-session" \
        --add-flags "--proc /proc" \
        --add-flags "--dev /dev" \
        --add-flags "--tmpfs /tmp" \
        --add-flags "--ro-bind /nix /nix" \
        --add-flags "--ro-bind /etc /etc" \
        --add-flags "--ro-bind /run /run" \
        --add-flags "--bind $HOME/Downloads $HOME/Downloads" \
        --add-flags "--ro-bind $HOME/.config/${name} $HOME/.config/${name}" \
        ${lib.concatMapStringsSep " " (b: "--add-flags \"${b}\"") extraBinds} \
        --add-flags "--ro-bind ${pkg}/bin/${name} ${pkg}/bin/${name}" \
        --add-flags "${pkg}/bin/${name}"
    '';
in
{
  options.hardening.desktopApps = {
    enable = mkEnableOption "desktop application sandboxing via bubblewrap";

    firefox = {
      enable = mkEnableOption "sandboxed firefox wrapper" // { default = cfg.enable; };
    };

    discord = {
      enable = mkEnableOption "sandboxed discord wrapper" // { default = cfg.enable; };
    };
  };

  config = mkIf cfg.enable {
    # Example: replace firefox in systemPackages with a bwrap-wrapped version.
    # In practice you should bind Wayland/X11 sockets, GPU devices, etc.
    # See the module comments and README for extending these wrappers.
    environment.systemPackages = lib.optional cfg.firefox.enable (
      makeBwrapWrapper {
        pkg = pkgs.firefox;
        extraBinds = [
          # Minimal desktop binds (extend as needed for your compositor)
          "--ro-bind $XDG_RUNTIME_DIR/wayland-0 $XDG_RUNTIME_DIR/wayland-0"
          "--dev-bind /dev/dri /dev/dri"
        ];
      }
    ) ++ lib.optional cfg.discord.enable (
      makeBwrapWrapper {
        pkg = pkgs.discord;
        extraBinds = [
          "--ro-bind $XDG_RUNTIME_DIR/wayland-0 $XDG_RUNTIME_DIR/wayland-0"
          "--dev-bind /dev/dri /dev/dri"
        ];
      }
    );
  };
}
