{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.ssh;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.ssh = {
    enable = mkEnableOption "SSH daemon hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.openssh.enable) {
    # sshd needs read access to user home dirs for authorized_keys.
    systemd.services.sshd.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      # sshd needs unix sockets for agent forwarding
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" "CAP_SYS_PTRACE" ];
     } // extraHardening;
  };
}
