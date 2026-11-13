{ config, lib, pkgs, ... }:

with lib;

{
  options.hardening.security.dbusHideProcessInformation = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Only allow users with group `proc` to retrieve systemd unit information like
      cgroup paths (i.e. (sub)process command lines) via D-Bus.

      This mitigates a systemd security issue where (sub)process command lines can
      be retrieved by services even when their access to /proc is restricted
      (via ProtectProc).

      This option works by restricting the D-Bus method `GetUnitProcesses`, which
      is also used internally by {command}`systemctl status`.
    '';
  };

  config = mkIf config.hardening.security.dbusHideProcessInformation {
    users.groups.proc = {};

    services.dbus.packages = lib.mkAfter [
      (pkgs.writeTextDir "etc/dbus-1/system.d/harden-nix-dbus.conf" ''
        <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
          <policy user="root">
            <allow own="*"/>
            <allow send_destination="*"/>
            <allow send_interface="*"/>
          </policy>
          <policy group="proc">
            <allow send_destination="org.freedesktop.systemd1"
                   send_interface="org.freedesktop.DBus.Properties"
                   send_member="GetAll"/>
            <allow send_destination="org.freedesktop.systemd1"
                   send_interface="org.freedesktop.systemd1.Manager"
                   send_member="GetUnitProcesses"/>
          </policy>
          <policy context="default">
            <deny send_destination="org.freedesktop.systemd1"
                  send_interface="org.freedesktop.systemd1.Manager"
                  send_member="GetUnitProcesses"/>
          </policy>
        </busconfig>
      '')
    ];
  };
}
