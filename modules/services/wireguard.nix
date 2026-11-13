{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.wireguard;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.wireguard = {
    enable = mkEnableOption "WireGuard (wg-quick) hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && (config.networking.wg-quick.interfaces != {})) {
    systemd.services = mapAttrs' (name: _value: {
      name = "wg-quick-${name}";
      value = {
        serviceConfig = {
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = false; # may need to load wireguard module
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
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_IPC_LOCK" ];
          ReadWritePaths = [ "/etc/wireguard" ];
          UMask = "0027";
        } // extraHardening;
      };
    }) config.networking.wg-quick.interfaces;
  };
}
