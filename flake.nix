{
  description = "Pure-Nix security hardening modules for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };
  };

  outputs = { self, nixpkgs, nix-flatpak }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      nixosModules = {
        default = self.nixosModules.hardened-baseline;
        hardened-baseline = { config, pkgs, lib, ... }: {
          imports = [
            nix-flatpak.nixosModules.nix-flatpak
            ./modules/default.nix
          ];
        };
        kernel = ./modules/system/kernel.nix;
        network = ./modules/system/network.nix;
        systemd-profiles = ./modules/profiles/systemd-profiles.nix;
        flatpak = { config, pkgs, lib, ... }: {
          imports = [
            nix-flatpak.nixosModules.nix-flatpak
            ./modules/flatpak.nix
          ];
        };
      };

      packages = forAllSystems (system: rec {
        nix-to-flatpak = nixpkgs.legacyPackages.${system}.writeScriptBin "nix-to-flatpak"
          (builtins.readFile ./tools/flatpak-migrate/nix-to-flatpak);
        default = nix-to-flatpak;
      });

      checks = forAllSystems (system:
        import ./checks {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit lib nixpkgs system;
        }
      );
    };
}
