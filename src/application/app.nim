import ../kurumiX/gui/appGui
import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
# import nimgl/[opengl, glfw]
import opengl
import nglfw
import ../common/globals
import ../kurumiX/synthesizer/modules/outputModule
import ../kurumiX/synthesizer/synthesizeWave
import ../kurumiX/synthesizer/serialization
import std/random
import ../kurumiX/gui/history
import ../kurumi3/gui/kurumi3History

import ../kurumi3/gui/kurumi3Gui
import ../kurumi3/synth/globals
import ../kurumi3/synth/kurumi3Synth
import ../kurumi3/synth/operator
import ../kurumi3/synth/serialization

import themes
when defined(emscripten): 
    import jsbind/emscripten

const vampires = [
    "Flandre Scarlet",
    "Remilia Scarlet",
    "Kurumi",
    "Alucard",
    "Krul Tepes",
    "Dracula",
    "Mikaela Hyakuya"
]

proc drawSelector*(): void {.inline.} =    

    if(igBeginPopupModal("Select mode", nil)):

    # if(igBegin("Select mode", nil)):
        if(igButton("Kurumi 3")):
            synthMode = KURUMI_3
            isSelectorOpen = false
        if(igButton("Kurumi X")):
            synthMode = KURUMI_X
            isSelectorOpen = false
        igEndPopup()


proc processLoop() {.inline.} =
    nglfw.pollEvents()
    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    if(isSelectorOpen):
        igOpenPopup("Select mode")
        drawSelector()

    case synthMode:
    of NONE:
        discard
    of KURUMI_X:
        # discard
        drawApp()
    of KURUMI_3:
        drawKurumi()

    igRender()

    glClearColor(0.0f, 0.0f, 0.0f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    window.swapBuffers()
    nglfw.swapInterval(1)

when defined(emscripten):
    proc emscripten_set_main_loop*(f: proc() {.cdecl.}, a: cint, b: int32) {.importc.}

    proc emMainLoop() {.cdecl.} =
        if(window.windowShouldClose):
            # saveState()
            igOpenGL3Shutdown()
            igGlfwShutdown()
            context.igDestroyContext()

            window.destroyWindow()
            nglfw.terminate()
            # saveState()
            # when defined(emscripten):
            #     discard EM_ASM_INT("""
            #     FS.syncfs(function (err) {
            #         alert(err);
            #     });
            #     """)
            quit(0)
        processLoop()

proc glfwCreateWindow*(width: int32, height: int32, title: cstring = "NimGL", monitor: nglfw.Monitor = nil, share: nglfw.Window = nil, icon: bool = true): nglfw.Window =
  ## Creates a window and its associated OpenGL or OpenGL ES
  ## Utility to create the window with a proper icon.
  result = nglfw.createWindow(width, height, title, monitor, share)
#   if not icon: return result
#   var image = nglfw.GlfwImage(pixels: cast[ptr cuchar](nimglLogo[0].addr), width: nimglLogoWidth, height: nimglLogoHeight)
#   result.setWindowIcon(1, image.addr)
proc boot*(): void =
    # when defined(emscripten):
        # discard EM_ASM_INT("""
        # FS.MKDIR('/kurumi');
        # FS.mount(IDBFS, {}, '/kurumi');
        # FS.syncfs(true, function (err) {
        #     alert(err);
        # });
        # """)

    randomize()
    synthContext.moduleList[1] = constructOutputModule()
    synthContext.synthesize()

    kurumi3SynthContext = constructSynth()

    doAssert nglfw.init()

    nglfw.windowHint(nglfw.CONTEXT_VERSION_MAJOR, 3)
    nglfw.windowHint(nglfw.CONTEXT_VERSION_MINOR, 3)
    nglfw.windowHint(nglfw.OPENGL_FORWARD_COMPAT, nglfw.TRUE)
    nglfw.windowHint(nglfw.OPENGL_PROFILE, nglfw.OPENGL_CORE_PROFILE)
    nglfw.windowHint(nglfw.RESIZABLE, nglfw.TRUE)
    let vamp = "Kurumi-X ~ Modular Wavetable Workstation\t [" & vampires[rand(vampires.len - 1)] & "]"
    window = glfwCreateWindow(1280, 800, (vamp).cstring)
    when defined(emscripten):
        discard EM_ASM_INT("""
    document.title = UTF8ToString($0)
    """, vamp.cstring)
        discard
    if window == nil:
        quit(-1)

    window.makeContextCurrent()

    doAssert glInit()

    context = igCreateContext()
    setupMoonlightStyle()
    var io = igGetIO()
    io.configFlags = (io.configFlags.int or ImGuiConfigFlags.NavEnableKeyboard.int).ImGuiConfigFlags
    #let io = igGetIO()

    doAssert igGlfwInitForOpenGL(window, true)
    doAssert igOpenGL3Init()

    echo "hi"
    when not defined(emscripten): loadState()
    history.history = History(historyPointer: 0, historyStack: @[HistoryEvent(eventName: "start", synthState: synthContext.saveStateHistory())])
    k3history = History3(historyPointer: 0, historyStack: @[History3Event(eventName: "start", synthState: kurumi3SynthContext.saveStateHistory())])
    # context.

    loadAlgsText()
    when(not defined(emscripten)):
        while not window.windowShouldClose:
            processLoop()

        when not defined(emscripten): 
            saveState()
        igOpenGL3Shutdown()
        igGlfwShutdown()
        context.igDestroyContext()

        window.destroyWindow()
        nglfw.terminate()
        return
    else:
        emscripten_set_main_loop(emMainLoop, 0, 1)
        