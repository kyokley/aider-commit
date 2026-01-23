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
    test-commit
    test-cleanup
  '';

}
