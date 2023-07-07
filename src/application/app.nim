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
    "Mikaela Hyakuya"
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
    window = glfwCreateWindow(1280, 800, ("Kurumi-X ~ Modular Wavetable Workstation\t [" & vampires[rand(vampires.len - 1)] & "]").cstring)
    if window == nil:
        quit(-1)

    window.makeContextCurrent()

    doAssert glInit()

    let context = igCreateContext()
    #let io = igGetIO()

    doAssert igGlfwInitForOpenGL(window, true)
    doAssert igOpenGL3Init()

    echo "hi"
    loadState()

    while not window.windowShouldClose:
        drawApp()

    saveState()
    igOpenGL3Shutdown()
    igGlfwShutdown()
    context.igDestroyContext()

    window.destroyWindow()
    glfwTerminate()
    return