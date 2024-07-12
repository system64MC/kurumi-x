import imgui
import ../synth/globals
import ../synth/kurumi3Synth
import ../../common/globals
import kurumi3History
import math

proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

var
    waveDimsX: int32 = 32
    waveDimsY: int32 = 32
    dummySample: int32 = 32
    oversample: int32 = 4
    macroLen: int32 = 64
    macroFrame: int32 = 0

proc drawOutputWindow*(): void {.inline.} =
    # synthContext.synthesize()
    igBegin("Wave preview")
    igBeginChild("wave", ImVec2(x: 512 + 8, y: 256 + 4), true, flags = ImGuiWindowFlags.AlwaysAutoResize)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()

    for i in 0..<kurumi3SynthContext.synthInfos.waveDims.x:
        let x1 = floor(i.float64 * 512.0 / kurumi3SynthContext.synthInfos.waveDims.x.float64).float32
        let x2 = ceil((i.float64 * 512.0 / kurumi3SynthContext.synthInfos.waveDims.x.float64) + (512.0 / kurumi3SynthContext.synthInfos.waveDims.x.float64)).float32
        let sample = (kurumi3SynthContext.outputInt[i].float64 * (255.0/kurumi3SynthContext.synthInfos.waveDims.y.float64) + (kurumi3SynthContext.synthInfos.waveDims.y.float64/2)*(255.0/kurumi3SynthContext.synthInfos.waveDims.y.float64)).float32 
        dl.addRectFilled(
            position + ImVec2(x: x1 + 4, y: 128 + 2),    
            position + ImVec2(x: x2 + 4, y: -sample + 383 + 2),
            0xFF_4B_4B_C8.uint32    
        )
    igEndChild()
    if(igSliderInt("Length", kurumi3SynthContext.synthInfos.waveDims.x.addr, 1, 256)):
        if(kurumi3SynthContext.synthInfos.waveDims.x > 4096): kurumi3SynthContext.synthInfos.waveDims.x = 4096
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change wave length")
    if(igSliderInt("height", kurumi3SynthContext.synthInfos.waveDims.y.addr, 1, 255)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change wave height")

    
    
    igEnd()
    return