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
    auto-commit-msg.exec = ./prepare-commit-msg;
    gitac.exec = ''
     # Parse command line arguments
     add_all=false
     while [[ $# -gt 0 ]]; do
         case $1 in
             -a|--all)
                 add_all=true
                 shift
                 ;;
             *)
                 shift
                 ;;
         esac
     done

     # Run git add if --all flag is provided
     if [[ "$add_all" == true ]]; then
         git add -u
     fi

     # Exit immediately if there are no staged changes
     if [[ ! $(git diff --cached --name-only) ]]; then
         echo "Nothing to commit"
         exit 0
     fi

     temp_commit_file=$(mktemp)
     touch ''${temp_commit_file}
     auto-commit-msg "''${temp_commit_file}" message
     git commit -F "''${temp_commit_file}"

     rm -f "''${temp_commit_file}"
    '';
  };

  services = {
    wiremock = {
      enable = true;
      verbose = true;
      mappings = [
        {
          request = {
            method = "GET";
            url = "/api/generate";
          };
          response = {
            jsonBody = {
              "model" = "gpt-oss";
              "created_at" = "2026-01-22T21:40:00Z";
              "response" = "mock response";
              "done" = true;
              "total_duration" = 1500000000;
              "load_duration" = 1200000;
              "prompt_eval_count" = 12;
              "eval_count" = 25;
            };
            status = 200;
          };
        }
        {
          request = {
            method = "POST";
            url = "/api/show";
          };
          response = {
            jsonBody = {
              "details" = {
                "format" = "mxfp4";
                "family" = "gptoss";
                "families" = ["gptoss"];
                "parameter_size" = "21B";
                "quantization_level" = "MXFP4";
              };
              "model_info" = {
                "general.architecture" = "gptoss";
                "general.license" = "Apache-2.0";
                "general.parameter_count" = 20900000000;
                "general.quantization_version" = 1;
              };
            };
            status = 200;
          };
        }
        {
          request = {
            method = "POST";
            url = "/api/chat";
          };
          response = {
            jsonBody = {
              "model" = "gpt-oss";
              "created_at" = "2026-01-22T22:15:00Z";
              "message" = {
                "role" = "assistant";
                "content" = "mock response";
              };
              "done" = true;
              "total_duration" = 1200000000;
              "load_duration" = 1500000;
              "prompt_eval_count" = 25;
              "eval_count" = 18;
            };
            status = 200;
          };
        }
      ];
    };
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
