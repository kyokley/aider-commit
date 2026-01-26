{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in
  {
    checks.${system} = let
      TEST_MODEL = "qwen:0.5b";
      TEST_OLLAMA_PORT = 11434;
    in {
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
    };

    # Override build machines for tests
    nixConfig = {
      buildMachines = [
        {
          hostName = "localhost";
          system = "x86_64-linux";
          maxJobs = 1;
          speedFactor = 1;
          supportedFeatures = [ "benchmark" "big-parallel" "nixos-test" ];
        }
      ];
    };
  };
}
