{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.avahi;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.avahi = {
    enable = mkEnableOption "Avahi hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.avahi.enable) {
    systemd.services.avahi-daemon.serviceConfig = {
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
      # Avahi needs its runtime dir and config
      ReadWritePaths = [
        "/run/avahi-daemon"
      ];
      ReadOnlyPaths = [
        "/etc/avahi"
        "/usr/share/avahi"
        "/usr/share/dbus-1"
      ];
      # Avahi drops privileges; needs chown/setuid/setgid
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_KILL"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_CHROOT"
      ];
     } // extraHardening;
  };
}
