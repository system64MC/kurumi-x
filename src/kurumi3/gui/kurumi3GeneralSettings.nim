import imgui
import ../../common/globals
import ../../common/synthInfos
import ../synth/globals
import ../synth/serialization
import ../synth/kurumi3Synth
import kurumi3History
import math
when defined(emscripten): 
    import jsbind/emscripten

proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

when defined(emscripten):
    proc alertJs(text: string) {.EMSCRIPTEN_KEEPALIVE.} =
        let t = text.cstring
        discard EM_ASM_INT("""alert(UTF8ToString($0));""", t)

let normalizeOptions = ["None".cstring, "Normalize", "New Normalize"]

proc drawGeneralSettings*(): void {.inline.} =
    # kurumi3synthContext.synthesize()
    igBegin("General settings")
    if(igSliderInt("Normalize mode", kurumi3SynthContext.normalize.addr, 0, normalizeOptions.len - 1, normalizeOptions[kurumi3SynthContext.normalize], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit normalize mode")
    if(igSliderFloat("Gain", kurumi3SynthContext.gain.addr, 0, 4)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit gain")
    if(igSliderInt("Avg. Filter window", kurumi3SynthContext.smoothWin.addr, 0, 128, flags = ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Avg. Filter window")
    if(igSliderInt("Seq. Length", kurumi3SynthContext.synthInfos.macroLen.addr, 1, 256)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Seq. Length")
        # kurumi3synthContext.synthesize()
    # if(igIsItemDeactivated()):
        # registerHistoryEvent("Change sequance length")
    if(igSliderInt("Seq. Index", kurumi3SynthContext.synthInfos.macroFrame.addr, 0, kurumi3SynthContext.synthInfos.macroLen - 1, flags = ImGuiSliderFlags.AlwaysClamp)):
        kurumi3synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change sequence index")
    if(igSliderInt("Oversample", kurumi3SynthContext.synthInfos.oversample.addr, 1, 8, flags = ImGuiSliderFlags.AlwaysClamp)):
        kurumi3synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change oversample")
    

    if(igButton("Copy current wave str")):
        # when defined(emscripten): alertJs("test")
        kurumi3SynthContext.synthesize()
        discard
        # igSetClipboardText(kurumi3synthContext.generateWaveStr().cstring)

    # igSameLine()
    if(igButton("Copy current wave str (HEX)")):
        discard
        # igSetClipboardText(kurumi3synthContext.generateWaveStr(true).cstring)

    # igSameLine()
    if(igButton("Copy sequence string")):
        discard
        # igSetClipboardText(kurumi3synthContext.generateSeqStr().cstring)
    
    igEnd()
    return