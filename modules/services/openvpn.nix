{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.openvpn;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.openvpn = {
    enable = mkEnableOption "OpenVPN server hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && (config.services.openvpn.servers != {})) {
    systemd.services = mapAttrs' (name: _value: {
      name = "openvpn-${name}";
      value = {
        serviceConfig = {
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
            "AF_PACKET"
          ];
          SystemCallFilter = [ "@system-service" "~@debug" "~@cpu-emulation" "~@obsolete" "~@reboot" ];
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_IPC_LOCK" ];
          ReadWritePaths = [ "/var/lib/openvpn" ];
          UMask = "0027";
        } // extraHardening;
      };
    }) config.services.openvpn.servers;
  };
}
