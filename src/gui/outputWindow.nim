import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import ../synthesizer/globals
import math
import ../synthesizer/synthesizeWave
# import nimclipboard/libclipboard

# proc drawOscilloscope(module: SynthModule, index: int): void {.inline.} =
#     igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
#     var position = ImVec2()
#     igGetWindowPosNonUDT(position.addr)
#     var dl = igGetWindowDrawList()
#     for i in 0..<OSC_W.int:
#         var color = COLOR_NORMAL
#         let half = (OSC_H / 2)
#         let sample = -module.synthesize(i.float64 / OSC_W)
#         if(sample > 1 or sample < -1): color = COLOR_SATURATE
#         let x = (sample) * half
#         dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
#     igEndChild()

# var cb = clipboard_new(nil)

proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

proc drawOutputWindow*(): void {.inline.} =
    # synthesize()
    igBegin("Output")
    igBeginChild("wave", ImVec2(x: 512 + 8, y: 256 + 4), true, flags = ImGuiWindowFlags.AlwaysAutoResize)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()

    for i in 0..<synthContext.waveDims.x:
        let x1 = floor(i.float64 * 512.0 / synthContext.waveDims.x.float64).float32
        let x2 = ceil((i.float64 * 512.0 / synthContext.waveDims.x.float64) + (512.0 / synthContext.waveDims.x.float64)).float32
        let sample = (outputInt[i].float64 * (255.0/synthContext.waveDims.y.float64) + (synthContext.waveDims.y.float64/2)*(255.0/synthContext.waveDims.y.float64)).float32 
        dl.addRectFilled(
            position + ImVec2(x: x1 + 4, y: 128 + 2),    
            position + ImVec2(x: x2 + 4, y: -sample + 383 + 2),
            0xFF_4B_4B_C8.uint32    
        )
    igEndChild()
    if(igSliderInt("Length", synthContext.waveDims.x.addr, 1, 256)):
        if(synthContext.waveDims.x > 4096): synthContext.waveDims.x = 4096
        synthesize()
    if(igSliderInt("height", synthContext.waveDims.y.addr, 1, 255)):
        synthesize()
    if(igSliderInt("Oversample", synthContext.oversample.addr, 1, 8)):
        if(synthContext.oversample > 8): synthContext.oversample = 8
        synthesize()
    if(igSliderInt("Seq. Length", synthContext.macroLen.addr, 1, 256)):
        if(synthContext.macroFrame >= synthContext.macroLen): synthContext.macroFrame = synthContext.macroLen - 1
        synthesize()
    if(igSliderInt("Seq. Index", synthContext.macroFrame.addr, 0, synthContext.macroLen - 1)):
        if(synthContext.macroFrame >= synthContext.macroLen): synthContext.macroFrame = synthContext.macroLen - 1
        synthesize()

    if(igButton("Copy current wave str")):
        igSetClipboardText(generateWaveStr().cstring)

    igSameLine()
    if(igButton("Copy current wave str (HEX)")):
        igSetClipboardText(generateWaveStr(true).cstring)

    igSameLine()
    if(igButton("Copy sequence string")):
        igSetClipboardText(generateSeqStr().cstring)
    
    igEnd()
    return