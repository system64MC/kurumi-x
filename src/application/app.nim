import ../gui/appGui
import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import ../synthesizer/globals
import ../synthesizer/modules/outputModule
import ../synthesizer/synthesizeWave
import ../synthesizer/serialization
import std/random

const vampires = [
    "Flandre Scarlet",
    "Remilia Scarlet",
    "Kurumi",
    "Alucard",
    "Krul Tepes",
    "Dracula",
]

proc boot*(): void =
    randomize()
    synthContext.moduleList[1] = constructOutputModule()
    synthesize()
    doAssert glfwInit()

    glfwWindowHint(GLFWContextVersionMajor, 3)
    glfwWindowHint(GLFWContextVersionMinor, 3)
    glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
    glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
    glfwWindowHint(GLFWResizable, GLFWTrue)
    var w: GLFWWindow = glfwCreateWindow(1280, 800, ("Kurumi-X ~ Modular Wavetable Workstation\t [" & vampires[rand(vampires.len - 1)] & "]").cstring)
    if w == nil:
        quit(-1)

    w.makeContextCurrent()

    doAssert glInit()

    let context = igCreateContext()
    #let io = igGetIO()

    doAssert igGlfwInitForOpenGL(w, true)
    doAssert igOpenGL3Init()

    echo "hi"
    loadState()

    while not w.windowShouldClose:
        drawApp(w)

    saveState()
    igOpenGL3Shutdown()
    igGlfwShutdown()
    context.igDestroyContext()

    w.destroyWindow()
    glfwTerminate()
    return