import imgui
import outputWindow
import grid
import moduleCreateMenu
import moduleDraw
import ../synthesizer/exportFile
import ../synthesizer/globals
import std/os
import history
when not defined(emscripten): import std/threadpool
# import malebolgia

let demo = true

proc drawApp*(): void {.inline.} =
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
                # var m = createMaster()
                if(igBeginMenu(".WAV")):
                    if(igMenuItem("8-Bits .WAV")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveWav(data, 8, false))
                        else: saveWav(data, 8, false)
                        # saveWav(data, 8, false)
                    if(igMenuItem("8-Bits .WAV (Sequence)")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveWav(data, 8, true))
                        else: saveWav(data, 8, true)
                        # saveWav(data, 8, true)
                    if(igMenuItem("16-Bits .WAV")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveWav(data, 16, false))
                        else: saveWav(data, 16, false)
                        # saveWav(data, 16, false)
                    if(igMenuItem("16-Bits .WAV (Sequence)")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveWav(data, 16, true))
                        else: saveWav(data, 16, true)
                        # saveWav(data, 16, true)
                    igEndMenu()

                if(igBeginMenu("SunVox")):
                    if(igMenuItem("Generator")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveGenerator(data))
                        else: saveGenerator(data)
                    if(igMenuItem("Analog Generator")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveAnalogGenerator(data))
                        else: saveAnalogGenerator(data)
                    if(igMenuItem("FMX")):
                        let data = history.history.historyStack[history.history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveFMX(data))
                        else: saveFMX(data)
                    # if(igMenuItem("16-Bits .WAV")):
                    #     let data = history.history.historyStack[history.history.historyPointer].synthState
                    #     when not defined(emscripten):
                    #         spawn(saveWav(data, 16, false))
                    #     else: saveWav(data, 16, false)
                    # if(igMenuItem("16-Bits .WAV (Sequence)")):
                    #     let data = history.history.historyStack[history.history.historyPointer].synthState
                    #     when not defined(emscripten):
                    #         spawn(saveWav(data, 16, true))
                    #     else: saveWav(data, 16, true)
                    igEndMenu()
                
                if(igMenuItem("Dn-Famitracker (N163)")):
                    let data = history.history.historyStack[history.history.historyPointer].synthState
                    when not defined(emscripten): spawn data.saveN163(false)
                    else: data.saveN163(false)
                if(igMenuItem("Dn-Famitracker (N163, with sequence)")):
                    let data = history.history.historyStack[history.history.historyPointer].synthState
                    when not defined(emscripten): spawn data.saveN163(true)
                    else: data.saveN163(true)
                if(igMenuItem("Furnace Wave (FUW)")):
                    let data = history.history.historyStack[history.history.historyPointer].synthState
                    when not defined(emscripten): spawn data.saveFUW()
                    else: data.saveFUW()
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
            igSeparator()
            if(igMenuItem("Change mode")):
                # synthMode = NONE
                isSelectorOpen = true
            igEndMenu()
        igEndMainMenuBar()
    
    if(igBegin("Main Rack", nil)):
        drawGrid()
    igEnd()

    drawOutputWindow()

  