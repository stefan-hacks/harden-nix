{ pkgs, lib, nixpkgs, system }:

let
  testModule = { config, pkgs, lib, ... }: {
    imports = [ (import ../modules/default.nix) ];
    hardening.enable = true;
    hardening.flatpak.enable = false;
    system.stateVersion = "26.05";
  };
in
{
  # VM test: verify the baseline module evaluates and boots
  baselineBoots = pkgs.testers.nixosTest {
    name = "hardening-baseline-boot";

    nodes.machine = { config, pkgs, ... }: {
      imports = [ testModule ];
      # Provide a minimal config so the VM can boot
      boot.loader.grub.device = "/dev/vda";
      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.succeed("sysctl kernel.yama.ptrace_scope | grep 2")
      machine.succeed("sysctl net.ipv4.tcp_syncookies | grep 1")
    '';
  };

  # VM test: verify nginx hardening does not break the service
  nginxHardening = pkgs.testers.nixosTest {
    name = "nginx-hardening";

    nodes.machine = { config, pkgs, ... }: {
      imports = [ testModule ];
      services.nginx = {
        enable = true;
        virtualHosts.localhost = {
          locations."/".return = "200 'ok'";
        };
      };
      networking.firewall.allowedTCPPorts = [ 80 ];
      boot.loader.grub.device = "/dev/vda";
      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("nginx.service")
      machine.succeed("curl -s http://localhost/ | grep ok")
      # Verify some hardening options are present in the unit
      machine.succeed("systemctl show nginx.service --property ProtectSystem | grep strict")
      machine.succeed("systemctl show nginx.service --property NoNewPrivileges | grep yes")
    '';
  };

  # VM test: verify mosquitto hardening does not break MQTT
  mosquittoHardening = pkgs.testers.nixosTest {
    name = "mosquitto-hardening";

    nodes.machine = { config, pkgs, ... }: {
      imports = [ testModule ];
      services.mosquitto = {
        enable = true;
        listeners = [{
          port = 1883;
          omitPasswordAuth = true;
          settings.allow_anonymous = true;
        }];
      };
      networking.firewall.allowedTCPPorts = [ 1883 ];
      boot.loader.grub.device = "/dev/vda";
      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("mosquitto.service")
      # Verify hardening options are present in the unit
      machine.succeed("systemctl show mosquitto.service --property ProtectSystem | grep strict")
      machine.succeed("systemctl show mosquitto.service --property NoNewPrivileges | grep yes")
      machine.succeed("systemctl show mosquitto.service --property PrivateDevices | grep yes")
      # Verify the broker port is listening
      machine.succeed("ss -tlnp | grep ':1883'")
    '';
  };
}
