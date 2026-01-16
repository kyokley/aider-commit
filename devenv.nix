{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/scripts/
  scripts.auto-commit-msg.exec = ./prepare-commit-msg;

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    auto-commit-message = {
      enable = true;
      name = "Auto commit message";
      entry = "auto-commit-msg";
      stages = ["prepare-commit-msg"];
    };
  };
}
