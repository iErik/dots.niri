{
  description = "Erik's personal Niri dots flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules = {
      default = self.homeManagerModules.dots;
      dots = import ./nix/default.nix self;
    };
  };
}
