{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.vaultwarden;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.vaultwarden = {
    enable = mkEnableOption "Vaultwarden hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.vaultwarden.enable) {
    systemd.services.vaultwarden.serviceConfig = {
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
        "/var/lib/vaultwarden"
        "/var/lib/bitwarden_rs"
      ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
    } // extraHardening;
  };
}
