{
  pkgs,
  config,
  ...
}: {
  config = {
    # https://devenv.sh/scripts/
    scripts.auto-commit-msg.exec = ./prepare-commit-msg;

    # https://devenv.sh/git-hooks/
    git-hooks.hooks = {
      auto-commit-message = {
        name = "Auto commit message";
        description = "Automatically generate commit messages with AI";
        entry = "auto-commit-msg";
        stages = ["prepare-commit-msg"];
      };
    };
  };
}
