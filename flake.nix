{
  description = "Pure-Nix security hardening modules for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      nixosModules = {
        default = self.nixosModules.hardened-baseline;
        hardened-baseline = ./modules/default.nix;
        kernel = ./modules/system/kernel.nix;
        network = ./modules/system/network.nix;
        systemd-profiles = ./modules/profiles/systemd-profiles.nix;
        desktop-apps = ./modules/desktop/default.nix;
      };

      checks = forAllSystems (system:
        import ./checks {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit lib nixpkgs system;
        }
      );
    };
}
