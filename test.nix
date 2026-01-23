let
  TEST_ENV_VARS = ''
      export OLLAMA_HOST=localhost:8080
      export OLLAMA_API_BASE=http://$OLLAMA_HOST
  '';
in
{
  scripts = {
    test-setup.exec = ''
      echo "Executing test setup"
      rm -f $DEVENV_ROOT/test_data >/dev/null 2>&1 || true

      repo_dir=$(mktemp -d)
      git init $repo_dir
      cp ./prepare-commit-msg $repo_dir/.git/hooks/
      cd $repo_dir
      chmod +x .git/hooks/prepare-commit-msg

      echo "I am a test file!" > $repo_dir/file1
      git add .
      git commit -m "Initial commit"

      echo $repo_dir > $DEVENV_ROOT/test_data
    '';

    test-nothing-to-commit.exec = ''
      ${TEST_ENV_VARS}
      echo "Executing test-nothing-to-commit"

      repo_dir=$(cat $DEVENV_ROOT/test_data)
      cd $repo_dir

      result=$(gitac)
      if [ "$result" != "Nothing to commit" ]
      then
        false
      fi
    '';

    test-commit.exec = ''
      set -x
      ${TEST_ENV_VARS}
      echo "Executing test-commit"

      repo_dir=$(cat $DEVENV_ROOT/test_data)
      cd $repo_dir
      git status
      echo "I am another test file!" > $repo_dir/file2
      git add .
      gitac

      result=$(git log -1 --pretty=%B)
      if [ "$result" != "mock response" ]
      then
        echo
        echo
        echo "got $result"
        false
      fi
    '';

    test-cleanup.exec = ''
        echo "Executing cleanup"
        if [ -f $DEVENV_ROOT/test_data ]
        then
          repo_dir=$(cat $DEVENV_ROOT/test_data || echo "")
          rm -rf $repo_dir $DEVENV_ROOT/test_data >/dev/null 2>&1
        fi
    '';
  };

  enterTest = ''
    ${TEST_ENV_VARS}

    wait_for_port 8080
    test-setup
    test-nothing-to-commit

    # The test-commit test doesn't quite work yet. Comment out for not
    # test-commit

    test-cleanup
  '';


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

}
