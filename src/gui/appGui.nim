import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import outputWIndow
import grid
import moduleCreateMenu
import moduleDraw
import ../synthesizer/exportFile
import ../synthesizer/globals
import std/os
import history

let demo = true

proc drawApp*(): void {.inline.} =
    # var style = igGetStyle()

    glfwPollEvents()


    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()
    let canUndo = (history.history.historyPointer > 0)
    let canRedo = (history.history.historyPointer < history.history.historyStack.len() - 1)
    if(
        (igGetIO().keyCtrl and igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z))) xor
        (igGetIO().keyCtrl and igIsKeyPressed(87))
        ):
        if(canUndo): undo()

    if(igGetIO().keyCtrl and igIsKeyPressed(igGetKeyIndex(ImGuiKey.Y))):
        if(canRedo): redo()

    igShowDemoWindow(demo.addr)
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
        if(igBeginMenu("Action")):
            if(igMenuItem("Undo", shortcut = "CTRL + Z", enabled = canUndo)):
                undo()
            if(igMenuItem("Redo", shortcut = "CTRL + Y", enabled = canRedo)):
                redo()
            if(igBeginMenu("History")):
                for i in countdown((history.history.historyStack.len() - 1), 0):
                    if(igMenuItem((history.history.historyStack[i].eventName & "##" & $i).cstring)):
                        restoreToHistoryIndex(i)
                igEndMenu()
            igEndMenu()
        igEndMainMenuBar()
    
    if(igBegin("Main Rack", nil)):
        drawGrid()
    igEnd()

    drawOutputWindow()

    igRender()

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    window.swapBuffers()
    glfwSwapInterval(1)
    sleep(5)

  