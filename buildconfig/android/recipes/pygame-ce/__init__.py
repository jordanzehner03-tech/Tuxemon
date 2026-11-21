from pathlib import Path

from pythonforandroid.recipes.pygame import Pygame2Recipe


class PygameCERecipe(Pygame2Recipe):
    name = "pygame-ce"
    version = "2.5.7"
    url = "https://files.pythonhosted.org/packages/source/p/pygame-ce/pygame_ce-{version}.tar.gz"
    hostpython_prerequisites = ["Cython==3.2.4", "setuptools<82"]

    def prebuild_arch(self, arch):
        super().prebuild_arch(arch)
        setup = Path(self.get_build_dir(arch.arch)) / "Setup"
        content = setup.read_text()
        for line in (
            "system src_c/system.c $(SDL) $(DEBUG)",
            "geometry src_c/geometry.c $(SDL) $(DEBUG)",
            "_sdl2.controller src_c/_sdl2/controller.c $(SDL) $(DEBUG) -Isrc_c",
        ):
            if line not in content.splitlines():
                content += "\n" + line
        setup.write_text(content + "\n")


recipe = PygameCERecipe()
