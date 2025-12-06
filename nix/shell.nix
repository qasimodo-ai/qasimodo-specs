{ inputs, ... }:
{
  imports = [ inputs.make-shell.flakeModules.default ];

  perSystem =
    { config, ... }:
    {
      make-shells.default = {
        shellHook = ''
          ${config.pre-commit.installationScript}
          export FLAKE_ROOT=$(git rev-parse --show-toplevel)
        '';
      };
    };
}
