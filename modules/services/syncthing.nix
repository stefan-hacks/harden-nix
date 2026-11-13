{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.syncthing;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.syncthing = {
    enable = mkEnableOption "Syncthing hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.syncthing.enable) {
    systemd.services.syncthing.serviceConfig = {
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
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      # Syncthing needs its data/config directory and runtime
      ReadWritePaths = [
        "/var/lib/syncthing"
        "/run/syncthing"
      ];
      ReadOnlyPaths = [
        "/etc/syncthing"
      ];
      CapabilityBoundingSet = [
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
