# import nimprof
import application/app

proc main() =
    when defined(emscripten):
        boot()
    else:
        # echo("Hello World!")
        boot()

when isMainModule:
    main()