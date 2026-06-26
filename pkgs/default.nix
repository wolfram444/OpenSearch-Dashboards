{
  lib,
  stdenv,
  makeWrapper,
  fetchurl,
  nodejs,
  coreutils,
  which,
}:

with lib;

stdenv.mkDerivation rec {
  pname = "opensearch-dashboards";
  version = "3.5.0";

  src = fetchurl {
    url = "https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/${version}/${pname}-${version}-linux-x64.tar.gz";
    hash = "sha256-g0aKKvi2rAd3AFdlfkotzoyREfoSTKJFI7bihjFu2wU=";
  };

  # Disables cleaning of debugging symbols
  dontStrip = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/libexec/opensearch-dashboards $out/bin
    mv * $out/lib/opensearch-dashboards/
    rm -r $out/libexec/opensearch-dashboards/node
    for bin in $out/libexec/opensearch-dashboards/bin/opensearch-dashboards*; do
      makeWrapper $bin $out/bin/$(basename $bin) \
        --prefix PATH : "${
          lib.makeBinPath [
            nodejs
            coreutils
            which
          ]
        }"
    done
    rm -rf $out/libexec/opensearch-dashboards/plugins/securityDashboards 
  '';

  meta = {
    description = "Visualization and user interface for OpenSearch";
    homepage = "https://opensearch.org";
    license = licenses.asl20;
    platforms = with platforms; linux;
    mainProgram = "opensearch-dashboards";
  };
}
