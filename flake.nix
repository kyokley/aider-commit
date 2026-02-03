{
  description = "Aider-Commit Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
      });
  in
  {
    packages = forAllSystems (system: with nixpkgsFor.${system}; {
      aider-commit-msg =
        stdenv.mkDerivation {
          name = "aider-commit-msg v${version}";
          src = ./.;
          nativeBuildInputs = [makeWrapper];
          installPhase = ''
            mkdir -p $out/bin

            cp prepare-commit-msg $out/bin/aider-commit-msg
            chmod +x $out/bin/aider-commit-msg
            wrapProgram $out/bin/aider-commit-msg \
              --prefix PATH : ${lib.makeBinPath [
                git
                gnugrep
                coreutils
                aider-chat
              ]}
          '';
        };

      gitac = stdenv.mkDerivation {
        name = "gitac v${version}";
        src = ./.;
        nativeBuildInputs = [makeWrapper];
        installPhase = ''
          mkdir -p $out/bin

          cp gitac $out/bin/gitac
          chmod +x $out/bin/gitac
          wrapProgram $out/bin/gitac \
            --prefix PATH : ${lib.makeBinPath [
              git
              coreutils
              self.packages.${system}.aider-commit-msg
            ]}
        '';
      };
    });

    apps = forAllSystems (system: with nixpkgsFor.${system}; {
      gitac = {
        type = "app";
        program = "${self.packages.${system}.gitac}/bin/gitac";
      };
      default = self.apps.${system}.gitac;
    });

    checks = forAllSystems (system: with nixpkgsFor.${system}; {
      unit-test = testers.runNixOSTest {
        name = "Aider-Commit Test";
        nodes = {
          client = {
            environment = {
              systemPackages = [
                self.packages.${system}.gitac
                git
              ];
              variables = {
                AIDER_COMMIT_MSG_OVERRIDE = "test commit message";
              };
            };
          };
        };
        testScript = ''
          start_all()

          client.execute('git config --global user.email "test@user"')
          client.execute('git config --global user.name "Test User"')
          client.execute("git init /tmp/test-dir")
          client.execute("""
            cd /tmp/test-dir &&
            echo 'print("hello world")' > main.py &&
            git add . &&
            git commit -m "Initial commit"
          """)

          status, stdout = client.execute("""
            cd /tmp/test-dir &&
            gitac
          """)
          assert stdout.strip() == "Nothing to commit"

          client.execute("""
            cd /tmp/test-dir &&
            echo 'print("foo")' > main.py &&
            gitac -a
          """)

          status, stdout = client.execute("""
            cd /tmp/test-dir &&
            git log -1 --pretty=%B
          """)
          assert "test commit message" in stdout.lower()

        '';
      };

      functional-test = let
            # ai_model = "qwen3:0.6b";
            ai_model = "llama3.2:3b";
            source = builtins.fetchGit {
              url = "https://github.com/kyokley/aider-commit";
              rev = "e5df3090ebf2fe8a75fa83894bc14e0620bc8508";
            };
            test_dir = "/tmp/test_dir";
          in testers.runNixOSTest {
        name = "AI Test";
        nodes = {
          machine = {
            virtualisation = {
              memorySize = 12 * 1024;
              diskSize = 20 * 1024;
              # Enable GPU passthrough
              graphics = true;
            };

            # Ollama server setup
            services.ollama = {
              enable = true;
              loadModels = [
                ai_model
              ];
            };

            environment = {
              etc."test_dir".source = source;
              systemPackages = [
                pkgs.ollama-rocm
                pkgs.git
                self.packages.${system}.gitac
              ];
              variables = {
                AIDER_COMMIT_CMD = "aider";
                AIDER_COMMIT_MODEL = "ollama_chat/${ai_model}";
                AIDER_COMMIT_TIMEOUT = "600";
              };
            };
          };
        };
        testScript = ''
          start_all()

          # machine.execute("git clone https://github.com/kyokley/aider-commit.git ${test_dir}")

          # Configure git identity for commits in the test VM
          machine.succeed('git config --global user.email "test@example.com"')
          machine.succeed('git config --global user.name "Test User"')
          machine.succeed('cp -Lrv /etc/test_dir ${test_dir} && git init ${test_dir} && cd ${test_dir} && git add devenv.* flake.* && git commit -m "Initial commit"')

          # machine.succeed("""
          #   git init ${test_dir} &&
          #   cd ${test_dir} &&
          #   touch file1 file2 file3 &&
          #   git add . &&
          #   git commit -am 'Initial Commit'""")

          machine.wait_for_open_port(11434)
          machine.wait_for_console_text("${ai_model}\s+success")

          status, out = machine.execute("""cd ${test_dir} && echo 'Begin processing' && gitac -a""")
          print(out)

          status, out = machine.execute("""cd ${test_dir} && git status""")
          print(out)

          status, out = machine.execute("""cd ${test_dir} && git log -1 --pretty=%B""")
          print(out)
        '';
      };
    });
  };
}
