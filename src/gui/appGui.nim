import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import outputWIndow
import grid
import moduleCreateMenu
import ../synthesizer/exportFile

let demo = true

proc drawApp*(w: GLFWWindow): void {.inline.} =
    var style = igGetStyle()

    glfwPollEvents()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    # igShowDemoWindow(demo.addr)
    if(igBeginMainMenuBar()):
        if(igBeginMenu("File")):
            if(igMenuItem("Save patch")):
                echo "Saving Patch"
            if(igMenuItem("Load patch")):
                echo "Loading Patch"
            
            if(igBeginMenu("Export")):
                if(igBeginMenu(".WAV")):
                    if(igMenuItem("8-Bits .WAV")):
                        saveWav(8, false)
                    if(igMenuItem("8-Bits .WAV (Sequence)")):
                        saveWav(8, true)
                    if(igMenuItem("16-Bits .WAV")):
                        saveWav(16, false)
                    if(igMenuItem("16-Bits .WAV (Sequence)")):
                        saveWav(16, true)
                    igEndMenu()
                
                if(igMenuItem("Dn-Famitracker (N163)")):
                    saveN163(false)
                if(igMenuItem("Dn-Famitracker (N163, with sequence)")):
                    saveN163(true)
                if(igMenuItem("Furnace Wave (FUW)")):
                    saveFUW()
                if(igMenuItem("Deflemask Wave (DMW)")):
                    saveDMW()
                igEndMenu()

            igEndMenu()
        igEndMainMenuBar()
    
    if(igBegin("Test", nil)):
        drawGrid()
    igEnd()

    drawOutputWindow()

    igRender()
    # sleep(5)

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    w.swapBuffers()
    glfwSwapInterval(1)

  