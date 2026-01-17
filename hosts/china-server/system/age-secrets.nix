# age-secrets.nix
{ config, lib, ... }:

{
  age.identityPaths = [
    "/home/${config.user.name}/.ssh/vw_wt"
  ];
  
  age.secrets = {
    azure-token = {
      file = ../secrets/azure-token.age;
      owner = config.user.name;
    };
    
    web = {
      file = ../secrets/web.age;
      owner = config.user.name;
    };
  };
}