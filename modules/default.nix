{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening;
  profiles = config.hardening.profiles;

  # Helper: enable all hardening options for a list of service names
  enableServices = names: listToAttrs (map (name: {
    name = "hardening.services.${name}.enable";
    value = mkDefault true;
  }) names);
in
{
  imports = [
    # System-level modules
    ./system/kernel.nix
    ./system/network.nix
    ./system/extra-hardening.nix

    # Reusable systemd archetypes
    ./profiles/systemd-profiles.nix

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

    profiles = {
      web-server = {
        enable = mkEnableOption "web server hardening profile (nginx, apache, caddy, lighttpd, php-fpm)";
      };
      database = {
        enable = mkEnableOption "database hardening profile (postgresql, mysql, redis, mongodb, memcached)";
      };
      mail = {
        enable = mkEnableOption "mail hardening profile (dovecot, postfix)";
      };
      messaging = {
        enable = mkEnableOption "messaging hardening profile (mosquitto, matrix-synapse)";
      };
      network = {
        enable = mkEnableOption "network hardening profile (ssh, dns, vpn, ntp, avahi, tor)";
      };
      storage = {
        enable = mkEnableOption "storage / file sharing hardening profile (samba, syncthing, nextcloud, minio)";
      };
      security = {
        enable = mkEnableOption "security tools hardening profile (fail2ban, vaultwarden, crowdsec)";
      };
      containers = {
        enable = mkEnableOption "container runtime hardening profile (docker, containerd, podman)";
      };
      logging = {
        enable = mkEnableOption "logging hardening profile (rsyslog)";
      };
      all = {
        enable = mkEnableOption "all service hardening profiles at once";
      };
    };
  };

  config = mkMerge [
    # Baseline system hardening (always on when hardening.enable = true)
    (mkIf cfg.enable {
      hardening.kernel.enable = mkDefault true;
      hardening.network.enable = mkDefault true;
      hardening.systemd.enable = mkDefault true;
    })

    # ─── Profile: Web Servers ───
    (mkIf (profiles.web-server.enable || profiles.all.enable) {
      hardening.services.nginx.enable = mkDefault true;
      hardening.services.apache.enable = mkDefault true;
      hardening.services.caddy.enable = mkDefault true;
      hardening.services.lighttpd.enable = mkDefault true;
      hardening.services.phpFpm.enable = mkDefault true;
    })

    # ─── Profile: Databases ───
    (mkIf (profiles.database.enable || profiles.all.enable) {
      hardening.services.postgresql.enable = mkDefault true;
      hardening.services.mysql.enable = mkDefault true;
      hardening.services.redis.enable = mkDefault true;
      hardening.services.mongodb.enable = mkDefault true;
      hardening.services.memcached.enable = mkDefault true;
    })

    # ─── Profile: Mail ───
    (mkIf (profiles.mail.enable || profiles.all.enable) {
      hardening.services.dovecot.enable = mkDefault true;
      hardening.services.postfix.enable = mkDefault true;
    })

    # ─── Profile: Messaging ───
    (mkIf (profiles.messaging.enable || profiles.all.enable) {
      hardening.services.mosquitto.enable = mkDefault true;
      hardening.services.matrix-synapse.enable = mkDefault true;
    })

    # ─── Profile: Network / DNS / VPN ───
    (mkIf (profiles.network.enable || profiles.all.enable) {
      hardening.services.ssh.enable = mkDefault true;
      hardening.services.dnsmasq.enable = mkDefault true;
      hardening.services.unbound.enable = mkDefault true;
      hardening.services.bind.enable = mkDefault true;
      hardening.services.avahi.enable = mkDefault true;
      hardening.services.ntpd.enable = mkDefault true;
      hardening.services.chrony.enable = mkDefault true;
      hardening.services.tor.enable = mkDefault true;
      hardening.services.wireguard.enable = mkDefault true;
      hardening.services.openvpn.enable = mkDefault true;
    })

    # ─── Profile: Storage ───
    (mkIf (profiles.storage.enable || profiles.all.enable) {
      hardening.services.samba.enable = mkDefault true;
      hardening.services.syncthing.enable = mkDefault true;
      hardening.services.nextcloud.enable = mkDefault true;
      hardening.services.minio.enable = mkDefault true;
    })

    # ─── Profile: Security Tools ───
    (mkIf (profiles.security.enable || profiles.all.enable) {
      hardening.services.fail2ban.enable = mkDefault true;
      hardening.services.vaultwarden.enable = mkDefault true;
      hardening.services.crowdsec.enable = mkDefault true;
    })

    # ─── Profile: Containers ───
    (mkIf (profiles.containers.enable || profiles.all.enable) {
      hardening.services.docker.enable = mkDefault true;
      hardening.services.containerd.enable = mkDefault true;
      hardening.services.podman.enable = mkDefault true;
    })

    # ─── Profile: Logging ───
    (mkIf (profiles.logging.enable || profiles.all.enable) {
      hardening.services.rsyslog.enable = mkDefault true;
    })
  ];
}
