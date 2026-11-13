{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.dovecot;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.dovecot = {
    enable = mkEnableOption "Dovecot hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.dovecot2.enable) {
    systemd.services.dovecot.serviceConfig = {
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
      # Dovecot needs these paths
      ReadWritePaths = [
        "/var/lib/dovecot"
        "/var/run/dovecot"
        "/run/dovecot"
      ];
      ReadOnlyPaths = [
        "/etc/dovecot"
        "/usr/share/dovecot"
      ];
      # Reduce capabilities — dovecot only needs basic net + chown
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_DAC_READ_SEARCH"
        "CAP_KILL"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
