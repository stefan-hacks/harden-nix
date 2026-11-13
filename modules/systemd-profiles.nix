{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.systemd;

  profiles = {
    network-daemon = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      SystemCallFilter = "@system-service";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
    };

    local-worker = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      PrivateNetwork = true;
      SystemCallFilter = "@system-service";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
    };

    web-server = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };

    database = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
  };
in
{
  options.hardening.systemd = {
    enable = mkEnableOption "reusable systemd hardening profiles";

    services = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          profile = mkOption {
            type = types.nullOr (types.enum (attrNames profiles));
            default = null;
            description = ''
              Security archetype to apply to this service.
              - network-daemon: general daemon with internet access
              - local-worker: background worker with no network
              - web-server: HTTP/s service needing unix sockets
              - database: database service needing unix sockets
            '';
          };

          extraServiceConfig = mkOption {
            type = types.attrs;
            default = {};
            description = "Extra serviceConfig merged after the archetype.";
          };
        };
      });
      default = {};
      example = literalExpression ''
        {
          my-api.profile = "network-daemon";
          my-worker.profile = "local-worker";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services = mapAttrs (name: serviceCfg:
      let
        base = if serviceCfg.profile != null
          then profiles.${serviceCfg.profile}
          else {};
      in
      {
        serviceConfig = mkMerge [
          base
          serviceCfg.extraServiceConfig
        ];
      }
    ) cfg.services;
  };
}
