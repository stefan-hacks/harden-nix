{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.ssh;
in
{
  options.hardening.services.ssh = {
    enable = mkEnableOption "SSH daemon hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.openssh.enable) {
    # sshd needs read access to user home dirs for authorized_keys.
    systemd.services.sshd.serviceConfig = {
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
    };
  };
}
