{
  description = "ansible-tf2network development nix flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
  in {
    devShells."${system}".default =
    let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    pkgs.mkShell {
      packages = with pkgs; [ ansible gnumake ];
      shellHook = ''
        eval `ssh-agent -s`
        ssh-add
      '';
    };
  };
}
