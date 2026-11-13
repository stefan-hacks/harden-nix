{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.tor;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.tor = {
    enable = mkEnableOption "Tor daemon hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.tor.enable) {
    systemd.services.tor.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@cpu-emulation" "~@obsolete" "~@reboot" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" "CAP_SETUID" "CAP_SETGID" "CAP_DAC_READ_SEARCH" ];
      ReadWritePaths = [
        "/var/lib/tor"
        "/var/cache/tor"
      ];
      UMask = "0027";
    } // extraHardening;
  };
}
