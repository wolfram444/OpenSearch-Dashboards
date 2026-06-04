{
  description = "OpenSearch Dashboards";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" ];

      flake = {
        nixosModules.default = import ./module.nix;
      };

      perSystem =
        { pkgs, self', ... }:
        {

          formatter = pkgs.nixfmt;
          packages = {
            opensearch-dashboards = pkgs.callPackage ./default.nix { };

            default = self'.packages.opensearch-dashboards;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixd
              nixfmt
              # (yarn.override {
              #   nodejs = nodejs_20;
              # })
              python3
              # jdk17
            ];
          };
        };
    };
}

# outputs = { self, nixpkgs }:
#   let
#     system = "x86_64-linux";
#     pkgs = import nixpkgs {
#       inherit system;
#     };
#   in {
#     packages.${system} = {
#       default = self.packages.${system}.opensearch-dashboards;
#       opensearch-dashboards = pkgs.callPackage ./default.nix {  };
#     };

#     devShells.${system}.default = pkgs.mkShell {
#       buildInputs = with pkgs; [
#         nixd
#         nodejs_20
#         (yarn.override {
#           nodejs = nodejs_20;
#         })
#         python3
#         jdk17
#       ];
#     };
#   };
