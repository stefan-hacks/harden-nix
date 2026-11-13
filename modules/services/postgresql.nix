{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.postgresql;
in
{
  options.hardening.services.postgresql = {
    enable = mkEnableOption "PostgreSQL hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.postgresql.enable) {
    systemd.services.postgresql.serviceConfig = {
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
      # PostgreSQL needs its data and log directories
      ReadWritePaths = [
        "/var/lib/postgresql"
        "/var/log/postgresql"
      ];
    };
  };
}
