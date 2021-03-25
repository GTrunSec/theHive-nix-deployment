{ config, lib, pkgs, ... }:

{
  services.cassandra = {
    enable = true;
    clusterName = "thp";
    package = pkgs.cassandra_3_11;
    extraConfig = {
      authenticator = "PasswordAuthenticator";
      authorizer = "CassandraAuthorizer";
    };
    remoteJmx = true;
    jmxRoles = [
      {
        username = "thehive";
        password = "thehive-password";
      }
    ];
  };
}
