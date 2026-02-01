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
      test = testers.runNixOSTest {
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
            cd /tmp/test-dir && \
            echo 'print("hello world")' > main.py && \
            git add . && \
            git commit -m "Initial commit"
          """)

          status, stdout = client.execute("""
            cd /tmp/test-dir && \
            gitac
          """)
          assert stdout.strip() == "Nothing to commit"

          client.execute("""
            cd /tmp/test-dir && \
            echo 'print("foo")' > main.py && \
            gitac -a
          """)

          status, stdout = client.execute("""
            cd /tmp/test-dir && \
            git log -1 --pretty=%B
          """)
          assert "test commit message" in stdout.lower()

        '';
      };
    });
  };
}
