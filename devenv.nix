{
  pkgs,
  config,
  inputs,
  ...
}: {
  # imports = [./test.nix];

  packages = [ pkgs.git ];

  # https://devenv.sh/scripts/
  scripts = {
    aider-commit-msg.exec = ./prepare-commit-msg;
    gitac.exec = ./gitac;
  };

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    aider-commit = {
      name = "Aider commit message";
      description = "Automatically generate commit messages with Aider";
      entry = "aider-commit-msg";
      stages = ["prepare-commit-msg"];
    };
  };
}
