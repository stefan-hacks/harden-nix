{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening;
in
{
  imports = [
    # System-level modules
    ./system/kernel.nix
    ./system/network.nix
    ./system/extra-hardening.nix

    # Reusable systemd archetypes
    ./profiles/systemd-profiles.nix

    # Desktop application sandboxing
    ./desktop/default.nix

    # Security helpers
    ./security/dbus-hide-processes.nix
    ./security/operator.nix

    # ─── Web Servers ───
    ./services/nginx.nix
    ./services/apache.nix
    ./services/caddy.nix
    ./services/lighttpd.nix

    # ─── Databases ───
    ./services/postgresql.nix
    ./services/mysql.nix
    ./services/redis.nix
    ./services/mongodb.nix
    ./services/memcached.nix

    # ─── Mail ───
    ./services/dovecot.nix
    ./services/postfix.nix

    # ─── Messaging ───
    ./services/mosquitto.nix
    ./services/matrix-synapse.nix

    # ─── Networking / DNS / VPN ───
    ./services/ssh.nix
    ./services/dnsmasq.nix
    ./services/unbound.nix
    ./services/bind.nix
    ./services/avahi.nix
    ./services/ntpd.nix
    ./services/chrony.nix
    ./services/tor.nix
    ./services/wireguard.nix
    ./services/openvpn.nix

    # ─── Storage / File Sharing ───
    ./services/samba.nix
    ./services/syncthing.nix
    ./services/nextcloud.nix
    ./services/minio.nix

    # ─── Languages / Runtimes ───
    ./services/php-fpm.nix

    # ─── Security ───
    ./services/fail2ban.nix
    ./services/vaultwarden.nix
    ./services/crowdsec.nix

    # ─── Containers ───
    ./services/docker.nix
    ./services/containerd.nix
    ./services/podman.nix

    # ─── Logging ───
    ./services/rsyslog.nix
  ];

  options.hardening = {
    enable = mkEnableOption "all hardening modules (baseline preset)";
  };

  # When the baseline preset is enabled, flip on every submodule.
  config = mkIf cfg.enable {
    hardening.kernel.enable = mkDefault true;
    hardening.network.enable = mkDefault true;
    hardening.systemd.enable = mkDefault true;
    hardening.desktopApps.enable = mkDefault false; # opt-in: changes visible desktop apps
  };
}
