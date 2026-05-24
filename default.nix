{ pkgs }:
pkgs.stdenvNoCC.mkDerivation (final: {
  name = "OpenSearch-Dashboards";
  version = "3.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "opensearch-project";
    repo = final.name;
    rev = final.version;
    sha256 = "sha256-d5sBRyP8rKl5uoj1t9D+mzfTVJXnwk3UguwXVgSbrd8=";
  };

  yarnOfflineCache = pkgs.fetchYarnDeps {
    yarnLock = final.src + "/yarn.lock";
    hash = "sha256-4MwS6xn6SRnTJ8QJwRnBOyZR+q2HVWWjROA8Bv0pbJY=";
  };

  nativeBuildInputs = with pkgs; [
    (yarnConfigHook.override {
      fixup-yarn-lock = fixup-yarn-lock.override {
        nodejs-slim = nodejs_20;
      };
      prefetch-yarn-deps = prefetch-yarn-deps.override {
        nodejs-slim = nodejs_20;
      };
      yarn = yarn.override {
        nodejs = nodejs_20;
      };
    })
    yarnBuildHook
    yarnInstallHook
    nixfmt
    nodejs_20
  ];
})
