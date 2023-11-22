from confy/nimble as run import nil
from confy/cfg  as cfg import nil

# Package

version       = "0.1.0"
author        = "System64MC"
description   = "Kurumi-X wavetable workstation"
license       = "MIT"
srcDir        = "src"
bin           = @["kurumiX"]


# Dependencies

requires "nim >= 1.9.3"
# requires "nimgl"
requires "https://github.com/nimgl/opengl.git"
requires "https://github.com/nimgl/glfw.git"
requires "https://github.com/system64MC/imgui.git#head"
requires "https://github.com/heysokam/nglfw.git"
# requires "https://github.com/daniel-j/nimgl-imgui.git"
requires "flatty"
requires "print"
requires "supersnappy"
requires "tinydialogs"
requires "kissfft"
requires "mathexpr"
requires "malebolgia"
requires "unrolled"
requires "https://github.com/heysokam/confy"
requires "jsbind"
requires "stew"
requires "sdl2"

# Build task
task confy, ".....": run.confy()