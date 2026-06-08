{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.opensearch-dashboards;
  format = pkgs.formats.yaml { };

  # Merge default settings with user-provided settings
  settingsFile = format.generate "opensearch_dashboards.yml" cfg.settings;
in

{

  options.services.opensearch-dashboards = {

    enable = lib.mkEnableOption "OpenSearch Dashboards";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./default.nix { };
      description = "OpenSearch Dashboards package";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "opensearch-dashboards";
      description = "User under which OpenSearch Dashboards runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "opensearch-dashboards";
      description = "Group under which OpenSearch Dashboards runs.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which the HTTP server listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5601;
      description = "TCP port for the HTTP server.";
    };

    opensearchHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "http://localhost:9200" ];
      example = [
        "https://node1:9200"
        "https://node2:9200"
      ];
      description = "List of OpenSearch node URLs.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;

        options = {
          "server.host" = lib.mkOption {
            type = lib.types.str;
            default = cfg.listenAddress;
            description = "Bind address (server.host in YAML).";
          };

          "server.port" = lib.mkOption {
            type = lib.types.port;
            default = cfg.port;
            description = "HTTP port (server.port in YAML).";
          };

          "opensearch.hosts" = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = cfg.opensearchHosts;
            description = "OpenSearch hosts (opensearch.hosts in YAML).";
          };
        };
      };
      default = { };
      example = lib.literalExpression ''
        {
          "server.basePath"               = "/dashboards";
          "opensearch.ssl.verificationMode" = "certificate";
          "opensearch.username"           = "kibanaserver";
          "opensearch.password"           = "changeme";
          "logging.dest"                  = "stdout";
        }
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opensearch-dashboards";
      description = "Directory for OpenSearch Dashboards runtime data and optimised bundles.";
    };

    logDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/log/opensearch-dashboards";
      description = "Directory for log files.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        NODE_OPTIONS = "--max-old-space-size=1024";
      };
      description = "Extra environment variables for the OpenSearch Dashboards process.";
    };
  };

  config = lib.mkIf cfg.enable {

    # Ensure the convenience options are forwarded into `settings` when the
    # user has not overridden them explicitly.
    services.opensearch-dashboards.settings = lib.mkMerge [
      {
        "server.host" = lib.mkDefault cfg.listenAddress;
        "server.port" = lib.mkDefault cfg.port;
        "opensearch.hosts" = lib.mkDefault cfg.opensearchHosts;
        # Point at our writable data directory
        "path.data" = lib.mkDefault cfg.dataDir;
      }
    ];

    users.users.${cfg.user}  = {
        description = "OpenSearch Dashboards service user";
        group = cfg.group;
        home = cfg.dataDir;
        isSystemUser = true;
      };

    users.groups.${cfg.group} = {

    };

    systemd.services.opensearch-dashboards = {
      description = "OpenSearch Dashboards";
      documentation = [ "https://docs.opensearch.org/latest/dashboards/" ];

      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "opensearch.service"
      ];

      environment = {
        # Let OSD find its own Node.js runtime shipped inside the package
        NODE_HOME = "${cfg.package}";
        # DISABLE_SECURITY_PLUGIN = "true";
      }
      // cfg.environment;

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          "${cfg.package}/bin/opensearch-dashboards"
          "--config"
          settingsFile
          "--path.data"
          cfg.dataDir
          "--logging.dest"
          "${cfg.logDir}/opensearch-dashboards.log"
        ];

        User = cfg.user;
        Group = cfg.group;

        # Filesystem hardening
        StateDirectory = baseNameOf cfg.dataDir;
        StateDirectoryMode = "0750";
        LogsDirectory = baseNameOf cfg.logDir;
        LogsDirectoryMode = "0750";
        RuntimeDirectory = "opensearch-dashboards";
        RuntimeDirectoryMode = "0750";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          cfg.dataDir
          cfg.logDir
        ];

        # Resource limits
        LimitNOFILE = 65536;
        TimeoutStartSec = 120;
        Restart = "on-failure";
        RestartSec = 5;
      };

      preStart = ''
        # Make sure data and log directories exist and are owned correctly
        install -d -m 0750 -o ${cfg.user} -g ${cfg.group} \
          "${cfg.dataDir}" "${cfg.logDir}"
      '';
    };

    #
    networking.firewall.allowedTCPPorts = [ config.services.opensearch-dashboards.port ];
  };

}
