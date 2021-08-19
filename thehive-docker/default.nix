{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.thehive-docker;
  dockerComposeFile = pkgs.writeText "docker-compose.yml" (import ./docker-compose.nix {
    port = cfg.port;
    host = cfg.host;
    JOB_DIRECTORY = cfg.JOB_DIRECTORY;
    cortexConf = cfg.cortexConf;
    thehiveConf = cfg.thehiveConf;
  });
in
{
  options.services.thehive-docker = {
    enable = mkOption { type = types.bool; default = false; };
    image = mkOption { type = types.str; };
    port = mkOption { type = types.int; default = 8334; };
    host = mkOption { type = types.str; default = "192.168.122.243"; };
    JOB_DIRECTORY = mkOption { type = types.path; default = "/var/lib/thehive-docker"; };
    cortexConf = mkOption { type = with types; str; default = "${./cortex-application.conf}"; };
    thehiveConf = mkOption { type = with types; str; default = "${./thehive-application.conf}"; };
  };

  config = mkIf cfg.enable {
    systemd.services.thehive-docker = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      requires = [ "docker.service" ];
      environment = { COMPOSE_PROJECT_NAME = "thehive-docker"; };
      serviceConfig = mkMerge [
        {
          ExecStart = "${pkgs.docker_compose}/bin/docker-compose -f '${dockerComposeFile}' up --build";
          ExecStop = "${pkgs.docker_compose}/bin/docker-compose -f '${dockerComposeFile}' stop";
          Restart = "always";
        }
      ];
    };
  };
}
