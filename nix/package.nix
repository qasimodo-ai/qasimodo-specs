{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      pyproject = lib.importTOML ../pyproject.toml;
      python = pkgs.python313;

      workspaceRoot = lib.fileset.toSource {
        root = ../.;
        fileset = lib.fileset.unions [
          ../pyproject.toml
          ../uv.lock
          ../README.md
          ../LICENSE
          ../src
          ../scripts
        ];
      };

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace { inherit workspaceRoot; };

      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

      pythonSet = (pkgs.callPackage inputs.pyproject-nix.build.packages { inherit python; }).overrideScope (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
        ]
      );
    in
    {

      packages = {
        default = config.packages.dist;

        dist = config.packages.qasimodo-specs.dist;

        qasimodo-specs = pythonSet.qasimodo-specs.overrideAttrs (old: {
          version = pyproject.project.version;
          __intentionallyOverridingVersion = true;

          outputs = [
            "out"
            "dist"
          ];

          postInstall = ''
            mkdir -p $dist

            install -Dm644 dist/*.whl -t $dist/

            SDIST_DIR=/build/qasimodo-specs-${pyproject.project.version}
            mkdir -p $SDIST_DIR

            cp -r ${workspaceRoot}/* $SDIST_DIR/

            cat > $SDIST_DIR/PKG-INFO <<EOF
            Metadata-Version: 2.1
            Name: qasimodo-specs
            Version: ${pyproject.project.version}
            Summary: ${pyproject.project.description}
            Requires-Python: ${pyproject.project.requires-python}
            EOF

            tar -czf $dist/qasimodo_specs-${pyproject.project.version}.tar.gz \
              -C /build qasimodo-specs-${pyproject.project.version}
          '';

          meta = {
            maintainers = [ lib.maintainers.aciceri ];
            license = lib.licenses.agpl3Plus;
          };
        });

        publish = pkgs.writeShellScriptBin "publish" ''
          ${lib.getExe pkgs.uv} publish ${config.packages.dist}/*
        '';
      };

      checks.qasimodo-specs = config.packages.qasimodo-specs;

      make-shells.default = {
        packages = with pkgs; [
          uv
          pythonSet.python
        ];
      };
    };
}
