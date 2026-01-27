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
        overlays = [self.overlays.default];
      });
  in
  {
    packages = forAllSystems (system: with nixpkgsFor.${system}; {
      aider-commit-msg =
        stdenv.mkDerivation {
          name = "aider-commit-msg v${version}";
          src = ./.;
          nativeBuildInputs = [makeWrapper];
          buildPhase = ":";
          installPhase = ''
            mkdir -p $out/bin

            cp prepare-commit-msg $out/bin/aider-commit-msg
            chmod +x $out/bin/aider-commit-msg
            wrapProgram $out/bin/aider-commit-msg \
              --set PATH ${lib.makeBinPath [
                git
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
            --set PATH ${lib.makeBinPath [
              git
              self.packages.${system}.aider-commit-msg
            ]}
        '';
      };
    });

    checks = let
      TEST_MODEL = "qwen:0.5b";
      TEST_OLLAMA_PORT = 11434;
    in forAllSystems (system: with nixpkgsFor.${system}; {
      test = pkgs.testers.runNixOSTest {
        name = "Aider-Commit Test";
        nodes = {
          server = {
            virtualisation.memorySize = 4096;
            services.ollama = {
              enable = true;
              host = "0.0.0.0";
              loadModels = [
                TEST_MODEL
              ];
            };
            networking.firewall.allowedTCPPorts = [
              TEST_OLLAMA_PORT
            ];
          };
          client = {
            environment = {
              systemPackages = [
                pkgs.devenv
                pkgs.aider-chat
                pkgs.ollama
              ];
              variables = rec {
                AIDER_COMMIT_MODEL = "ollama_chat/${TEST_MODEL}";
                AIDER_MODEL = AIDER_COMMIT_MODEL;
                AIDER_SHOW_RELEASE_NOTES = "false";
                OLLAMA_HOST = "server:${toString TEST_OLLAMA_PORT}";
                OLLAMA_API_BASE = "http://${OLLAMA_HOST}";
              };
            };
          };
        };
        testScript = ''
          start_all()

          client.succeed("rm -rf /root/src")
          client.copy_from_host("./.", "/root/src")

          server.wait_for_open_port(11434)
          client.wait_until_succeeds("ollama list | grep qwen")
          client.succeed("aider --message 'respond to this prompt with 'I understand' | grep -i 'I understand'")
          client.execute("ls -l /root/src")
        '';
      };
    });
  };
}
