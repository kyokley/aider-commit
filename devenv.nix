{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [./test.nix];

  packages = [ pkgs.git ];

  # https://devenv.sh/scripts/
  scripts = {
    aider-commit-msg.exec = ./prepare-commit-msg;
    gitac.exec = ''
      # Parse command line arguments
      add_all=false
      show_help=false
      while [[ $# -gt 0 ]]; do
          case $1 in
              -a|--all)
                  add_all=true
                  shift
                  ;;
              -h|--help)
                  show_help=true
                  shift
                  ;;
              *)
                  shift
                  ;;
          esac
      done

      # Show help if requested
      if [[ "$show_help" == true ]]; then
          echo "Usage: gitac [OPTIONS]"
          echo "Automatically commit changes with AI-generated commit messages."
          echo ""
          echo "Options:"
          echo "  -a, --all    Run 'git add' before committing (adds all changes)"
          echo "  -h, --help   Show this help message"
          echo ""
          echo "If no changes are staged, the script will exit."
          exit 0
      fi

      # Run git add if --all flag is provided
      if [[ "$add_all" == true ]]; then
          git add .
      fi

      temp_commit_file=$(mktemp)
      touch ''${temp_commit_file}

      if auto-commit-msg "''${temp_commit_file}" message
      then
        git commit -F "''${temp_commit_file}"
      fi

      rm -f "''${temp_commit_file}"
    '';
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
