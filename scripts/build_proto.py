"""Build hook to compile protobuf files."""

import subprocess
from pathlib import Path
from hatchling.builders.hooks.plugin.interface import BuildHookInterface


class CustomBuildHook(BuildHookInterface):
    """Custom build hook to compile protobuf files."""

    def initialize(self, version, build_data):
        """Compile proto files before building."""
        proto_dir = Path("src/qasimodo_specs/proto")
        proto_files = list(proto_dir.glob("*.proto"))

        if not proto_files:
            return

        # Compile proto files
        for proto_file in proto_files:
            cmd = [
                "python",
                "-m",
                "grpc_tools.protoc",
                f"--proto_path={proto_dir}",
                f"--python_out={proto_dir}",
                str(proto_file),
            ]
            subprocess.run(cmd, check=True)
