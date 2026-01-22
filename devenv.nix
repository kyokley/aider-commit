{
  pkgs,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/scripts/
  scripts = {
    auto-commit-msg.exec = ./prepare-commit-msg;
    gitac.exec = ''
     # Exit immediately if there are no staged changes
     if ! git diff --cached --name-only > /dev/null 2>&1; then
         exit 0
     fi

     temp_commit_file=$(mktemp)
     touch ''${temp_commit_file}
     auto-commit-msg "''${temp_commit_file}" message
     git commit -F "''${temp_commit_file}"
     cat "''${temp_commit_file}"
     rm -f "''${temp_commit_file}"
    '';
  };

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    auto-commit-message = {
      name = "Auto commit message";
      description = "Automatically generate commit messages with AI";
      entry = "auto-commit-msg";
      stages = ["prepare-commit-msg"];
    };
  };
}
