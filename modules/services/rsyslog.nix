{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.rsyslog;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.rsyslog = {
    enable = mkEnableOption "Rsyslog hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.rsyslogd.enable) {
    systemd.services.syslog.serviceConfig = {
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
      ReadWritePaths = [
        "/var/log"
        "/var/spool/rsyslog"
        "/var/lib/rsyslog"
      ];
      ReadOnlyPaths = [
        "/etc/rsyslog.conf"
        "/etc/rsyslog.d"
      ];
    } // extraHardening;
  };
}
