if defined(emscripten):
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
  when compileOption("threads"):
    # We can have a pool size to populate and be available on page run
    # --passL:"-sPTHREAD_POOL_SIZE=2"
    discard
  --listCmd # List what commands we are running so that we can debug them.

  --gc:arc # GC:arc is friendlier with crazy platforms.
  --exceptions:goto # Goto exceptions are friendlier with crazy platforms.
  --define:noSignalHandler # Emscripten doesn't support signal handlers.

  # Pass this to Emscripten linker to generate html file scaffold for us.
#   switch("passC", "-traditional")
  switch("passL", "-o step1.html --shell-file shell_minimal.html")
else:
    when defined(release):
      --boundChecks:off
      --overflowChecks:off
      --floatChecks:off
      --nanChecks:off
      --infChecks:off
    # else:
    #   --profiler:on
    #   --stacktrace:on
    # --d:debug
    # --cc:clang
    --backend:cpp
    --verbosity:1
    --threads:on
    # --d:ThreadPoolSize=8
    # --d :FixedChanSize=16
    --d:nimDontSetUtf8CodePage
    --opt:speed
    --passC:"-flto -O3 -Ofast"
    --passL:"-flto -s"
    --mm:arc
    --d:useMimAlloc 