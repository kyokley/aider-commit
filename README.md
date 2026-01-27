# Aider-Commit
Use [Aider](https://aider.chat/) to automatically generate git commit messages. `Aider-Commit` comes with a git hook to invoke a call to the LLM model of your choice to create a commit message based on the currently staged diffs. If `Aider-Commit` is installed through [devenv](https://devenv.sh/), an executable called `gitac` is also added to allow committing the AI generated commit message without any interaction (editor does not open and the commit message is automatically accepted).
## Requirements
Be sure to already have [Aider](https://aider.chat/) installed.
## Installation
There are a few different ways to install `Aider-Commit`.

### Option 1. Directly in .git/hooks
Copy `prepare-commit-msg` to .git/hooks in whatever git repo you'd like to use the plugin in. Be sure to make the script executable with `chmod +x prepare-commit-msg`
### Option 2. devenv.sh
If you're running [Nix](https://nixos.org/) and [devenv](https://devenv.sh/)
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
### Option 3. Standalone `gitac` with Nix
Run:
```
nix run github:kyokley/aider-commit
```
## Configuration
`Aider-Commit` makes the following environment variables available to allow overriding the default behavior of the git hook.
- `AIDER_COMMIT_CMD` - Aider command invoked to analyze diffs. (default: `aider`)
- `AIDER_COMMIT_MODEL` - AI model passed to the `AIDER_COMMIT_CMD`. (default: `ollama_chat/gpt-oss`)
## Usage
Write code and commit as usual

### gitac Usage
When installed through devenv, `Aider-Commit` provides a `gitac` command that allows for automated committing with AI-generated messages:

```
Usage: gitac [OPTIONS]

Automatically commit changes with AI-generated commit messages.
Options:
- `-a, --all`    Run 'git add' before committing (adds all changes)
- `-h, --help`   Show help message

If no changes are staged, the script will exit.
```
