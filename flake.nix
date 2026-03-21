{
  description = "Erik's personal Niri dots flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    wallpapers.url = "git+ssh://git@github.com/iErik/Wallpapers";
    wallpapers.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, wallpapers }: {
    homeManagerModules = {
      default = {
        imports = [
          self.homeManagerModules.dots
          wallpapers.homeManagerModules.default
        ];
      };

      dots = import ./nix/default.nix self wallpapers;
    };
  };
}
