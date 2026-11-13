{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.ntpd;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.ntpd = {
    enable = mkEnableOption "NTP daemon hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && (config.services.ntp.enable or false)) {
    systemd.services.ntpd.serviceConfig = {
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
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      # NTP needs drift files, logs, and pid files
      ReadWritePaths = [
        "/var/lib/ntp"
        "/var/log/ntp"
        "/run/ntp"
        "/run/nscd"
        "/var/db"
        "/var/tmp"
        "/tmp"
      ];
      ReadOnlyPaths = [
        "/etc/ntp.conf"
        "/etc/ntp"
        "/etc/ntpd.conf"
      ];
      # NTP needs time-setting and chroot capabilities
      CapabilityBoundingSet = [
        "CAP_DAC_OVERRIDE"
        "CAP_IPC_LOCK"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_CHROOT"
        "CAP_SYS_NICE"
        "CAP_SYS_RESOURCE"
        "CAP_SYS_TIME"
      ];
     } // extraHardening;
  };
}
