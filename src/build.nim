import confy

let code = srcDir/"kurumiX.nim"
var bin = Program.new(
  src   = code,
  trg   = "kurumiX.exe",
)

# cfg.zigSystemBin = on

# Declare the options
cfg.verbose = on
cfg.nimUnsafeFunctionPointers = on
bin.args = "--warning:HoleEnumConv:off --warning:UnusedImport:off"

# Now order to build
when defined(Windows):
  bin.trg = "kurumiX"
  bin.syst = System(os: OS.Windows, cpu: CPU.x86_64)
  bin.build()

when defined(Linux):
  bin.trg = "kurumiX"
  bin.syst = System(os: OS.Linux, cpu: CPU.x86_64)
  bin.build()

#_____________________
# Cross Compilation  |
#____________________|
when defined(CrossCompile):    # --d:CrossCompile in the src/build.nim.cfg file to run this part of the example
  # Build the same target for Windows
  bin.trg  = "kurumiX.exe"
  bin.syst = System(os: OS.Windows, cpu: CPU.x86_64)
  bin.build()

  # Build the same target for mac.x64
  bin.trg  = "kurumiX.app"
  bin.syst = System(os: OS.Mac, cpu: CPU.x86_64)
  bin.build()

  # Build the same target for mac.arm64
  # bin.trg  = "hello-nim-arm64.app"
  # bin.syst = System(os: OS.Mac, cpu: CPU.arm64)
  # bin.build()
