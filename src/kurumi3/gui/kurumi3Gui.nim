import imgui
import ../../common/globals
import ../../common/exportFile
import kurumi3OutputWindow
import kurumi3GeneralSettings
import kurumi3Matrix
import kurumi3Filters
import kurumi3Operators
import kurumi3History
import ../synth/kvpLoader
import ../synth/serialization
when defined(emscripten): import jsbind/emscripten
when not defined(emscripten): import std/threadpool

when defined(emscripten):
    proc myMalloc*(size: uint32): uint32 {.EMSCRIPTEN_KEEPALIVE, cdecl.} =
        let address = alloc(size)
        return cast[uint32](address)

    proc myFree*(address: uint32) {.EMSCRIPTEN_KEEPALIVE, cdecl.} =
        let addressMem = cast[ptr byte](address)
        dealloc(addressMem)

    proc ptrToString*(address: uint32) {.EMSCRIPTEN_KEEPALIVE, cdecl.} =
        let s = cast[cstring](address)
        let strData = $(s)
        
        loadKvp(strData)

    proc loadKvp() {.EMSCRIPTEN_KEEPALIVE.} =
        discard EM_ASM_INT("""
    function uploadFile(file) {
        var reader = new FileReader();
        reader.addEventListener("load", _=> {
        //reader.onload = function(e) {
            //alert("loading");
            var data = reader.result;
            //var obj;
            try {
                var obj = JSON.parse(data);
                //console.log(obj);
                //alert(JSON.parse(data));
                if(obj.Format != "vampire")
                {
                    alert("Not a Kurumi 3 KVP patch!");
                }
                else
                {
                    var ptr  = _myMalloc(data.length + 1);
                    for(var i = 0; i < data.length; i++ ) {
                        _setByte(ptr + i, data.charCodeAt(i));
                    }
                    _setByte(ptr + data.length, 0);
                    _ptrToString(ptr);
                    _myFree(ptr);
                    //alert("Good format!");
                }
            }
            catch(err) {
                //alert(err);
                alert("Cannot load file : Wrong format or KVP corrupted!");
                return;
            }
            
            file = [];
        });
        reader.readAsText(file);
        
    }

    const a = document.createElement('input');
    a.type = 'file';
    a.addEventListener('change', function(event) {
        var file = event.target.files[0];
        uploadFile(file);
        event.target.files[0] = [];
    });
    a.style = 'display:none';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    //uploadFile();
        """)

proc drawKurumi*(): void {.inline.} =
    let canUndo = (k3history.historyPointer > 0)
    let canRedo = (k3history.historyPointer < k3history.historyStack.len() - 1)
    if(
        (igGetIO().keyCtrl and igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z))) xor
        (igGetIO().keyCtrl and igIsKeyPressed(87))
        ):
        if(canUndo): undo()

    if(igGetIO().keyCtrl and igIsKeyPressed(igGetKeyIndex(ImGuiKey.Y))):
        if(canRedo): redo()


    if(igBeginMainMenuBar()):
        if(igBeginMenu("File")):
            if(igMenuItem("Load KVP")):
                when defined(emscripten): loadKvp()
                else: discard
            if(igBeginMenu("Export")):
                # var m = createMaster()
                if(igBeginMenu(".WAV")):
                    if(igMenuItem("8-Bits .WAV")):
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        when not defined(emscripten):
                            spawn(saveWav(data, 8, false))
                        else: saveWav(data, 8, false)
                        # saveWav(data, 8, false)
                    if(igMenuItem("8-Bits .WAV (Sequence)")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)

                        when not defined(emscripten):
                            spawn(saveWav(data, 8, true))
                        else: saveWav(data, 8, true)
                        # saveWav(data, 8, true)
                    if(igMenuItem("16-Bits .WAV")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        when not defined(emscripten):
                            spawn(saveWav(data, 16, false))
                        else: saveWav(data, 16, false)
                        # saveWav(data, 16, false)
                    if(igMenuItem("16-Bits .WAV (Sequence)")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        when not defined(emscripten):
                            spawn(saveWav(data, 16, true))
                        else: saveWav(data, 16, true)
                        # saveWav(data, 16, true)
                    igEndMenu()

                if(igBeginMenu("SunVox")):
                    if(igMenuItem("Generator")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        when not defined(emscripten):
                            spawn(saveGenerator(data))
                        else: saveGenerator(data)
                    if(igMenuItem("Analog Generator")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        when not defined(emscripten):
                            spawn(saveAnalogGenerator(data))
                        else: saveAnalogGenerator(data)
                    if(igMenuItem("FMX")):
                        # let data = k3history.historyStack[k3history.historyPointer].synthState
                        let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                        when not defined(emscripten):
                            spawn(saveFMX(data))
                        else: saveFMX(data)
                    # if(igMenuItem("16-Bits .WAV")):
                    #     let data = k3history.historyStack[k3history.historyPointer].synthState
                    #     when not defined(emscripten):
                    #         spawn(saveWav(data, 16, false))
                    #     else: saveWav(data, 16, false)
                    # if(igMenuItem("16-Bits .WAV (Sequence)")):
                    #     let data = k3history.historyStack[k3history.historyPointer].synthState
                    #     when not defined(emscripten):
                    #         spawn(saveWav(data, 16, true))
                    #     else: saveWav(data, 16, true)
                    igEndMenu()
                
                if(igMenuItem("Dn-Famitracker (N163)")):
                    # let data = k3history.historyStack[k3history.historyPointer].synthState
                    let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                    when not defined(emscripten): spawn data.saveN163(false)
                    else: data.saveN163(false)
                if(igMenuItem("Dn-Famitracker (N163, with sequence)")):
                    # let data = k3history.historyStack[k3history.historyPointer].synthState
                    let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
                    when not defined(emscripten): spawn data.saveN163(true)
                    else: data.saveN163(true)
                if(igMenuItem("Furnace Wave (FUW)")):
                    # let data = k3history.historyStack[k3history.historyPointer].synthState
                    let data = loadStateHistory(k3history.historyStack[k3history.historyPointer].synthState)
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
                for i in countdown((k3history.historyStack.len() - 1), 0):
                    if(igMenuItem((k3history.historyStack[i].eventName & "##" & $i).cstring)):
                        restoreToHistoryIndex(i)
                igEndMenu()
            igSeparator()

            if(igMenuItem("Change mode")):
                # synthMode = NONE
                isSelectorOpen = true
            igEndMenu()
        igEndMainMenuBar()

    igBegin("Kurumi 3 dummy Window", nil)
    igText("When the impostor is sus")
    igEnd()

    drawOutputWindow()
    drawGeneralSettings()
    drawMatrixWindow()
    drawFiltersWindow()
    drawOperatorsWindow()