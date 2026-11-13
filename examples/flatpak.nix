# Example: Declarative Flatpak desktop apps via harden-nix
#
# This module shows the simplest way to manage Flatpak apps with harden-nix:
#   1. Import harden-nix.nixosModules.default (which auto-imports nix-flatpak)
#   2. Enable hardening.flatpak
#   3. Add app IDs directly to services.flatpak.packages
#
# To find an app ID, run: flatpak search <name>
# Then copy the Application ID and paste it into the list below.

{ config, pkgs, ... }: {

  # Enable harden-nix baseline (includes nix-flatpak automatically)
  hardening.enable = true;

  # Enable secure Flatpak defaults (restricts filesystem to ~/Downloads,
  # enables weekly auto-updates)
  hardening.flatpak.enable = true;

  # ── Add your Flatpak apps here ──
  # Just run `flatpak search <name>` and paste the Application ID.
  services.flatpak.packages = [
    # Browsers
    "org.mozilla.firefox"
    "org.chromium.Chromium"

    # Communication
    "com.discordapp.Discord"
    "im.riot.Riot"
    "org.telegram.desktop"

    # Media
    "org.videolan.VLC"
    "io.mpv.Mpv"

    # Productivity
    "md.obsidian.Obsidian"
    "com.visualstudio.code"

    # Add more below...
  ];

  # Optional: add extra Flatpak remotes beyond flathub
  # services.flatpak.remotes = [
  #   { name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
  # ];

  # Optional: remove Flatpak apps not listed above (default: false)
  # services.flatpak.uninstallUnmanaged = true;
}
