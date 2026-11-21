from pathlib import Path
from shutil import copy2, copytree, ignore_patterns

from pythonforandroid.recipes.pygame import Pygame2Recipe


class PygameCERecipe(Pygame2Recipe):
    name = "pygame-ce"
    version = "2.5.7"
    url = "https://files.pythonhosted.org/packages/source/p/pygame-ce/pygame_ce-{version}.tar.gz"
    hostpython_prerequisites = ["Cython==3.2.4", "setuptools<82"]

    def prebuild_arch(self, arch):
        super().prebuild_arch(arch)
        build_dir = Path(self.get_build_dir(arch.arch))
        # Its x86 AVX2 compiler hook looks at the build host's CPU.
        # ARM64 uses the standard setuptools compiler invocation.
        script = build_dir / "setup.py"
        script.write_text(script.read_text().replace(
            "distutils.ccompiler.CCompiler.spawn = spawn", ""
        ))
        setup = build_dir / "Setup"
        content = setup.read_text()
        for line in (
            "system src_c/system.c $(SDL) $(DEBUG)",
            "geometry src_c/geometry.c $(SDL) $(DEBUG)",
            "_sdl2.controller src_c/_sdl2/controller.c $(SDL) $(DEBUG) -Isrc_c",
        ):
            if line not in content.splitlines():
                content += "\n" + line
        setup.write_text(content + "\n")

    def install_python_package(self, arch, **kwargs):
        # build_ext produced target ELF modules. A second pip build would
        # switch to pygame-ce's desktop Meson backend.
        source = Path(self.get_build_dir(arch.arch))
        destination = Path(self.ctx.get_site_packages_dir(arch)) / "pygame"
        copytree(source / "src_py", destination, dirs_exist_ok=True,
                 ignore=ignore_patterns("__briefcase", "__pyinstaller", "meson.build"))
        compiled, = (source / "build").glob("lib.*/pygame")
        for extension in compiled.rglob("*.so"):
            relative = extension.relative_to(compiled)
            filename = relative.name.split(".")[0] + ".so"
            copy2(extension, destination / relative.parent / filename)


recipe = PygameCERecipe()
