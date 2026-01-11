let 
  wt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2RIXbYQVSE11LdMIP1YAIAeG3gQP8KcW5SNZFmS7py agenix key";
in {
  "azure.age".publicKeys = [wt];
  "web.age".publicKeys = [wt];
  "MonoLisaVariableItalic.age".publicKeys = [wt];
  "MonoLisaVariableNormal.age".publicKeys = [wt];
}