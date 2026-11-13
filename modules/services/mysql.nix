{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.mysql;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.mysql = {
    enable = mkEnableOption "MySQL/MariaDB hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.mysql.enable) {
    systemd.services.mysql.serviceConfig = {
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
      # MySQL/MariaDB needs its data, tmp, and socket dirs
      ReadWritePaths = [
        "/var/lib/mysql"
        "/var/log/mysql"
        "/run/mysqld"
        "/run/mysql"
        "/tmp"
      ];
      ReadOnlyPaths = [
        "/etc/my.cnf"
        "/etc/mysql"
        "/usr/share/mysql"
      ];
      # MariaDB needs basic caps for file ownership
      CapabilityBoundingSet = [
        "CAP_DAC_OVERRIDE"
        "CAP_KILL"
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
