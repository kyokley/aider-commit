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
     # Exit immediately if there are no staged changes
     if [[ ! $(git diff --cached --name-only) ]]; then
         echo "Nothing to commit"
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
              "model" = "<string>";
              "created_at" = "<string>";
              "response" = "mock response";
              "thinking" = "<string>";
              "done" = true;
              "done_reason" = "<string>";
              "total_duration" = 123;
              "load_duration" = 123;
              "prompt_eval_count" = 123;
              "prompt_eval_duration" = 123;
              "eval_count" = 123;
              "eval_duration" = 123;
              "logprobs" = [
                {
                  "token" = "<string>";
                  "logprob" = 123;
                  "bytes" = [
                    123
                  ];
                  "top_logprobs" = [
                    {
                      "token" = "<string>";
                      "logprob" = 123;
                      "bytes" = [
                        123
                      ];
                    }
                  ];
                }
              ];
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
              message = {
                content = "mock response";
              };
              done = true;
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
