# Package

version       = "0.1.0"
author        = "System64MC"
description   = "Kurumi-X wavetable workstation"
license       = "MIT"
srcDir        = "src"
bin           = @["kurumiX"]


# Dependencies

requires "nim >= 1.9.3"
requires "nimgl"
requires "https://github.com/nimgl/imgui.git"
requires "flatty"
requires "supersnappy"
requires "tinydialogs"