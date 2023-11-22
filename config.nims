--backend:cpp
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

  --gc:orc # GC:orc is friendlier with crazy platforms.
  --exceptions:goto # Goto exceptions are friendlier with crazy platforms.
  --define:noSignalHandler # Emscripten doesn't support signal handlers.

  --define:useMalloc
  --opt:speed
  --threads:off
  --exceptions:cpp
  --define:jsbindNoEmJs
  --define:SDL_Static

  switch("passC", """-o3 -sNO_DISABLE_EXCEPTION_CATCHING""")
  # Pass this to Emscripten linker to generate html file scaffold for us.
  switch("passL", "-o index.html -sEXPORTED_RUNTIME_METHODS=allocate -sNO_DISABLE_EXCEPTION_CATCHING -s USE_WEBGL2=1 -sUSE_SDL=2 -lSDL2 -LC:/wasm32-emscripten -lidbfs.js --shell-file shell_minimal.html")