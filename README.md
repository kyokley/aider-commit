# Aider-Commit
Use Aider to automatically generate git commit messages
## Installation
### A. Directly in .git/hooks
Copy prepare-commit-msg to .git/hooks in whatever git repo you'd like to use the plugin in. Be sure to make the script executable with `chmod +x prepare-commit-msg`
### B. devenv.sh
1. Add aider-commit module to devenv.yaml as an input and import. The file should look like the following:
```
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling
  auto-commit-message:
    url: github:kyokley/aider-commit
    flake: false
imports:
  - auto-commit-message
```
2. Enable the hook in devenv.nix
```
git-hooks.hooks.auto-commit-message.enable = true;
```
## Configuration
Aider-commit makes the following environment variables available to allow overriding the default behavior of the git hook.
- `AIDER_COMMIT_CMD` - Aider command invoked to analyze diffs. (default: `aider`)
- `AIDER_COMMIT_MODEL` - AI model passed to the `AIDER_COMMIT_CMD`. (default: `ollama_chat/gpt-oss`)
## Usage
Write code and commit as usual
