{
  description = "OpenSearch Dashboards ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages.${system} = {
        default = self.packages.${system}.opensearch-dashboards;
        opensearch-dashboards = pkgs.callPackage ./default.nix {  };
      };

      
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixd
          nodejs_20
          (yarn.override {
            nodejs = nodejs_20;
          })
          python3
          jdk17
        ];
      };
    };
}
