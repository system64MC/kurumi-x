--backend:cpp
--gc:arc # GC:orc is friendlier with crazy platforms.

switch("warning", "HoleEnumConv:off")

when defined(emscripten):
  # This path will only run if -d:emscripten is passed to nim.

  --nimcache:tmp # Store intermediate files close by in the ./tmp dir.

  --os:linux # Emscripten pretends to be linux.
  --cpu:wasm32 # Emscripten is 32bits.
  --cc:clang # Emscripten is very close to clang, so we ill replace it.
  when defined(windows):
    --clang.exe:emcc.bat  # Replace C
    --clang.linkerexe:emcc.bat # Replace C linker
    --clang.cpp.exe:emcc.bat # Replace C++
    --clang.cpp.linkerexe:emcc.bat # Replace C++ linker.
  else:
    --clang.exe:emcc  # Replace C
    --clang.linkerexe:emcc # Replace C linker
    --clang.cpp.exe:emcc # Replace C++
    --clang.cpp.linkerexe:emcc # Replace C++ linker.
  --listCmd # List what commands we are running so that we can debug them.

  --exceptions:goto # Goto exceptions are friendlier with crazy platforms.
  --define:noSignalHandler # Emscripten doesn't support signal handlers.

  --define:useMalloc
  --opt:speed
  --threads:off
  --exceptions:cpp
  --define:jsbindNoEmJs
  --define:SDL_Static

  switch("passC", """-Ofast -flto -no-pie -funroll-loops -finline-functions -finline-small-functions -ftree-vectorize -sNO_DISABLE_EXCEPTION_CATCHING""")
  # Pass this to Emscripten linker to generate html file scaffold for us.
  switch("passL", "-o index.html -sALLOW_MEMORY_GROWTH -sEXPORTED_RUNTIME_METHODS=allocate -sNO_DISABLE_EXCEPTION_CATCHING -s USE_WEBGL2=1 -sUSE_SDL=2 -lSDL2 -LC:/wasm32-emscripten -lidbfs.js --shell-file shell_minimal.html")
# else:
#   switch("passC", """-Ofast -flto -no-pie -funroll-loops -finline-functions -finline-small-functions -fopt-info-vec -ftree-vectorize -march=x86-64-v3 -fipa-pta -fipa-reference -fipa-ra -fipa-sra -ffinite-math-only -fno-trapping-math -fassociative-math -freciprocal-math -funsafe-math-optimizations""")