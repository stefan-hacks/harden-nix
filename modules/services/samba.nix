{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.samba;
in
{
  options.hardening.services.samba = {
    enable = mkEnableOption "Samba (smbd/nmbd) hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.samba.enable) {
    systemd.services.smbd.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      # Samba needs its data, caches, and shares
      ReadWritePaths = [
        "/var/lib/samba"
        "/var/cache/samba"
        "/var/spool/samba"
        "/run/samba"
        "/run/dbus"
      ];
      ReadOnlyPaths = [
        "/etc/samba"
        "/usr/lib/samba"
        "/usr/share/samba"
      ];
      # Samba needs extensive capabilities for file serving
      CapabilityBoundingSet = [
        "CAP_AUDIT_WRITE"
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_DAC_READ_SEARCH"
        "CAP_FOWNER"
        "CAP_LEASE"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_ADMIN"
        "CAP_SYS_RESOURCE"
        "CAP_SYS_TTY_CONFIG"
      ];
    };

    systemd.services.nmbd.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      ReadWritePaths = [
        "/var/lib/samba"
        "/var/cache/samba"
        "/run/samba"
      ];
      ReadOnlyPaths = [
        "/etc/samba"
        "/usr/share/samba"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_BIND_SERVICE"
      ];
    };
  };
}
