# import ../synthesizer/modules/[
#     module,
#     oscillatorModule, 
#     fmModule, 
#     mixerModule, 
#     amplifierModule, 
#     absoluterModule, 
#     rectifierModule, 
#     clipperModule, 
#     inverterModule, 
#     pdModule, 
#     syncModule,
#     morphModule,
#     expModule,
#     multModule,
#     dualWaveModule,
#     averageModule,
#     fmProModule,
#     phaseModule,
#     waveFoldModule,
#     waveMirrorModule,
#     dcOffsetModule,
#     chordModule,
#     feedbackModule,
#     downsamplerModule,
#     quantizerModule,
#     outputModule,
#     lfoModule,
#     softClipModule,
#     waveFolderModule,
#     splitterModule,
#     normalizerModule,
#     bqFilterModule,
#     unisonModule,
#     noiseModule
# ]

import ../synthesizer/synth
import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import std/typeinfo
import ../synthesizer/globals
import ../synthesizer/utils/utils
import ../synthesizer/linkManagement
import ../synthesizer/synthesizeWave
import ../synthesizer/modules
import std/strutils
import math

# proc draw(module: SynthModule): void {.inline.} =
#     return

const
    # AABBGGRR format
    COLOR_OSCILLATOR = 0xFF003F00
    COLOR_FM = 0xFF00003F
    COLOR_MIXER = 0xFF3F0000

    OSC_W = 128.0
    OSC_H = 64.0

proc drawTitleBar(text: cstring, index: int, color: uint32 = 0xFF000000.uint32): void {.inline.} =
    # return
    var vec = ImVec2()
    igPushStyleColor(ImGuiCOl.ChildBg, color)
    
    igBeginChild(("titleBar" & ($index)).cstring, ImVec2(x: vec.x, y: 16))
    igGetContentRegionAvailNonUDT(vec.addr)
    let x = igGetCursorPosX()
    let y = igGetCursorPosY()
    igText(text)
    igSameLine(x + vec.x - 24)
    # igSetCursorPosX(x + vec.x - 24)
    if not(synthContext.moduleList[index] of OutputModule):
        if(igButton("X", ImVec2(x: 16, y: 16))):
            deleteModule(index)
            synthesize()
    igEndChild()
    igPopStyleColor()
    # igSetCursorPosY(y + 24)
    return



proc drawInputs(module: SynthModule, index: int): void {.inline.} =
    for i in 0..<module.inputs.len():
        if(igButton(("I##" & $i).cstring)):
            if(selectedLink.moduleIndex > -1 and selectedLink.pinIndex > -1):
                module.makeLink(index, i)
            else:
                module.breakLinksInput(i)
            synthesize()

proc drawOutputs(module: SynthModule, index: int): void {.inline.} =
    for i in 0..<module.outputs.len():
        if(igButton(("O##" & $i).cstring)):
            if(module.outputs[i].moduleIndex > -1 or module.outputs[i].pinIndex > -1): module.breakLinksOutput(i)
            selectedLink.moduleIndex = index.int16
            selectedLink.pinIndex = i.int16
            synthesize()

const
    COLOR_NORMAL = 0xFF_FF_FF_FF.uint32
    COLOR_SATURATE = 0xFF_7F_7F_FF.uint32

proc drawOscilloscope(module: SynthModule, index: int): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, 0)
        if(sample > 1 or sample < -1): color = COLOR_SATURATE
        let x = (sample) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()

proc drawOscilloscopeOut(module: OutputModule, index: int): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, module.inputs[0].pinIndex)
        if(sample > 1 or sample < -1): color = COLOR_SATURATE
        let x = (sample) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()

proc drawOscilloscopeFMPro(module: FmProModule, index: int): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        var sum = 0.0
        for pin in 0..<6:
            let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, pin)
            sum += sample
        if(sum > 1 or sum < -1): color = COLOR_SATURATE
        let x = (sum) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()

proc drawEnvelope(adsrPtr: ptr Adsr, maxPeak: float32): void {.inline.} =
    igBeginChild("envSettings")
    igBeginChild("env", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()

    # Attack and peak1
    dl.addLine(
        ImVec2(x: position.x + 4, y: position.y + 64.0f-adsrPtr.start*(64f / maxPeak) + 2),
        ImVec2(x: position.x + 4 + adsrPtr.attack.float32 / 2, y: position.y + 64.0f-adsrPtr.peak*(64f / maxPeak) + 2),
        0xFF_FF_FF_FF.uint32
    )

    # Decay and sustain
    dl.addLine(
        ImVec2(x: position.x + 4 + adsrPtr.attack.float32 / 2, y: position.y + 64.0f-adsrPtr.peak*(64f / maxPeak) + 2),
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay).float32 / 2, y: position.y + 64.0f-adsrPtr.sustain*(64f / maxPeak) + 2),
        0xFF_FF_FF_FF.uint32
    )

    # Attack2 and peak2
    dl.addLine(
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay).float32 / 2, y: position.y + 64.0f-adsrPtr.sustain*(64f / maxPeak) + 2),
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2).float32 / 2, y: position.y + 64.0f-adsrPtr.peak2*(64f / maxPeak) + 2),
        0xFF_FF_FF_FF.uint32
    )

    # Decay2 and Sustain2
    dl.addLine(
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2).float32 / 2, y: position.y + 64.0f-adsrPtr.peak2*(64f / maxPeak) + 2),
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2).float32 / 2, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
        0xFF_FF_FF_FF.uint32
    )

    # Sustain2
    dl.addLine(
        ImVec2(x: position.x + 4 + (adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2).float32 / 2, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
        ImVec2(x: position.x + 4 + (256).float32 / 2, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
        0xFF_FF_FF_FF.uint32
    )
    igEndChild()

    if(igSliderFloat("Start", adsrPtr.start.addr, 0, maxPeak)):
        synthesize()

    if(igSliderInt("Attack", adsrPtr.attack.addr, 0, 256)):
        synthesize()

    if(igSliderFloat("Peak", adsrPtr.peak.addr, 0, maxPeak)):
        synthesize()

    if(igSliderInt("Decay", adsrPtr.decay.addr, 0, 256)):
        synthesize()

    if(igSliderFloat("Sus", adsrPtr.sustain.addr, 0, maxPeak)):
        synthesize()

    if(igSliderInt("Attack 2", adsrPtr.attack2.addr, 0, 256)):
        synthesize()

    if(igSliderFloat("Peak 2", adsrPtr.peak2.addr, 0, maxPeak)):
        synthesize()

    if(igSliderInt("Decay 2", adsrPtr.decay2.addr, 0, 256)):
        synthesize()

    if(igSliderFloat("Sus 2", adsrPtr.sustain2.addr, 0, maxPeak)):
        synthesize()
    igText(("Keyframes : " & $(adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2)).cstring)
    igEndChild()
    
method draw(module: SynthModule, index: int): void {.inline, base.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("DUMMY MODULE", index, COLOR_FM.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: FmodModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM", index, COLOR_FM.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: FmProModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM Pro", index, COLOR_FM.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscopeFMPro(index)

    # igBeginChild("matrix")

    igBeginTable("opMatrix", 6)
    for i in 0..<6:
        for j in 0..<6:
            igTableNextColumn()
            if(igCheckbox(("##op" & $i & $j).cstring, module.matrix[i][j].addr)):
                synthesize()
    
    igEndTable()
    # igEndChild()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: MixerModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Mixer", index, COLOR_MIXER.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: AverageModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Average", index, COLOR_MIXER.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SineOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Sine Oscillator", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthesize()
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthesize()
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: TriangleOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Triangle Oscillator", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthesize()
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthesize()
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SawOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Saw Oscillator", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthesize()
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthesize()
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SquareOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Pulse Oscillator", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
            synthesize()
        if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
            synthesize()
        if(igSliderFloat("P. Width", module.dutyEnvelope.peak.addr, 0f, 1f)):
            synthesize()
        if(igSliderInt("Detune", module.detune.addr, -32, 32)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.dutyEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

const interpolations: array[3, cstring] = ["Nearest".cstring, "Linear", "Cubic"]
method draw(module: WavetableOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wavetable Oscillator", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthesize()
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthesize()
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthesize()

    var str = ($module.waveStr)
    str.setLen((module.waveStr.len) + 1024)
    var strC = str.cstring
    if(igInputText("Wavetable", strC, str.len.uint32 + 1024 + 1)):
        module.waveStr = $strC
        module.refreshWaveform()
        synthesize()

    if(igSliderInt("Interpolation", module.interpolation.addr, 0, interpolations.len - 1, format = interpolations[module.interpolation])):
        module.interpolation = clamp(module.interpolation, 0, interpolations.len - 1)
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: AmplifierModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Amplifier", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Amp.", module.envelope.peak.addr, 0.0f, 4.0f)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.envelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: AbsoluterModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Absoluter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: RectifierModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Rectifier", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: InverterModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Inverter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: ClipperModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Clipper", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderFloat("Max.", module.clipMax.addr, -4.0f, 4.0f)):
        synthesize()
    if(igSliderFloat("Min.", module.clipMin.addr, -4.0f, 4.0f)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: PdModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Phase Dist.", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("X Dist.", module.xEnvelope.peak.addr, 0.0f, 1.0f)):
            synthesize()
        if(igSliderFloat("Y Dist.", module.yEnvelope.peak.addr, 0.0f, 1.0f)):
            synthesize()
        if(igCheckbox("Use ADSR on X", module.useAdsrX.addr)):
            synthesize()
        if(igCheckbox("Use ADSR on Y", module.useAdsrY.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsrX):
        if(igBeginTabItem("ADSR Dist. X")):
            module.xEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    if(module.useAdsrY):
        if(igBeginTabItem("ADSR Dist. Y")):
            module.yEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SyncModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Sync", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()    
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Sync.", module.envelope.peak.addr, 0.0f, 16.0f)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.envelope.addr.drawEnvelope(16)
            igEndTabItem()
    igSetColumnOffset(2, vec.x - 20)
    igEndTabBar()

    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: MorphModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Morpher", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Morph.", module.envelope.peak.addr, 0.0f, 1.0f)):
            synthesize()
        igEndTabItem()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.envelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: ExpModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Exponenter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderFloat("Exp.", module.exponent.addr, 0.0f, 15.0f)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: MultModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Multiplier", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: DualWaveModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Dual Wave", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: PhaseModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Phase", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderFloat("Phase", module.phase.addr, 0.0f, 1.0f)):
        synthesize()
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: WaveFoldModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Folding", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: WaveMirrorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Mirroring", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderFloat("Mirror", module.mirrorPlace.addr, 0.0f, 1.0f)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: DcOffsetModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("DC Offset", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderFloat("Offset", module.offset.addr, -4.0f, 4.0f)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: ChordModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Chord", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igBeginChild("a")
    for i in 0..<module.mults.len:
        if(igSliderInt(("Mul " & $(i + 1)).cstring, module.mults[i].addr, 0, 32)):
            synthesize()
    igEndChild()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: FeedbackModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM Feedback", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Feedback", module.fbEnvelope.peak.addr, 0.0f, 4.0f)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.fbEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: DownsamplerModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Downsample", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()

    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Downsample", module.downsampleEnvelope.peak.addr, 0.0f, 1.0f)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.downsampleEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: QuantizerModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Quantizer", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()

    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index)
        if(igSliderFloat("Quant.", module.quantizationEnvelope.peak.addr, 0.0f, 1.0f)):
            synthesize()
        if(igCheckbox("Use ADSR", module.useAdsr.addr)):
            synthesize()
        igEndTabItem()
    if(module.useAdsr):
        if(igBeginTabItem("ADSR")):
            module.quantizationEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: OutputModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Output", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscopeOut(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

const lfoWaves: array[5, cstring] = ["Sine".cstring, "Triangle", "Saw", "Square", "Custom"]
const lfoModes: array[2, cstring] = ["Vibrato", "Tremollo"]
method draw(module: LfoModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("LFO", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("type", module.lfoType.addr, 0, 4, format = lfoWaves[module.lfoType])):
        module.lfoType = clamp(module.lfoType, 0, lfoWaves.len - 1)
        synthesize()
    if(igSliderInt("mode", module.lfoMode.addr, 0, 1, format = lfoModes[module.lfoMode])):
        module.lfoMode = clamp(module.lfoMode, 0, lfoModes.len - 1)
        synthesize()
    if(igSliderFloat("Intensity", module.intensity.addr, 0, 4)):
        synthesize()
    if(igSliderInt("Frequency", module.frequency.addr, 0, 16)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SoftClipModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Soft Clip", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

const foldTypes: array[3, cstring] = ["Sine".cstring, "LinFold", "Wrap"]
method draw(module: WaveFolderModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Folder", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Type", module.waveFoldType.addr, 0, 2, format = foldTypes[module.waveFoldType])):
        module.waveFoldType = clamp(module.waveFoldType, 0, foldTypes.len - 1)
        synthesize()
    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: SplitterModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Splitter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: NormalizerModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Normalizer", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

const filterTypes: array[5, cstring] = ["Lowpass".cstring, "Highpass", "Bandpass", "Bandstop", "Allpass"]
method draw(module: BqFilterModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Biquad Filter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index)
        module.drawOscilloscope(index)
        if(igSliderInt("Type", module.filterType.addr, 0, filterTypes.len - 1, format = filterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, filterTypes.len - 1)
            synthesize()
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthesize()
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthesize()
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthesize()
        if(igCheckbox("Use Cutoff ADSR", module.useCutoffEnvelope.addr)):
            synthesize()
        if(igCheckbox("Use Resonance ADSR", module.useQEnvelope.addr)):
            synthesize()
        if(igCheckbox("Normalize", module.normalize.addr)):
            synthesize()
        igEndChild()
        igEndTabItem()
    if(module.useCutoffEnvelope):
        if(igBeginTabItem("Cut. ADSR")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.useQEnvelope):
        if(igBeginTabItem("Res. ADSR")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return


const chFilterTypes: array[2, cstring] = ["Lowpass".cstring, "Highpass"]
method draw(module: ChebyshevFilterModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Chebyshev Filter", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index)
        module.drawOscilloscope(index)
        if(igSliderInt("Type", module.filterType.addr, 0, filterTypes.len - 1, format = chFilterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, filterTypes.len - 1)
            synthesize()
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthesize()
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthesize()
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthesize()
        if(igSliderInt("Order", module.order.addr, 0, 32)):
            synthesize()
        if(igCheckbox("Use Cutoff ADSR", module.useCutoffEnvelope.addr)):
            synthesize()
        if(igCheckbox("Use Resonance ADSR", module.useQEnvelope.addr)):
            synthesize()
        if(igCheckbox("Normalize", module.normalize.addr)):
            synthesize()
        igEndChild()
        igEndTabItem()
    if(module.useCutoffEnvelope):
        if(igBeginTabItem("Cut. ADSR")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.useQEnvelope):
        if(igBeginTabItem("Res. ADSR")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

method draw(module: UnisonModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Unison", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Unison", module.unison.addr, 0, 8)):
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

const noiseTypes: array[3, cstring] = ["LSFR 1-Bit".cstring, "LSFR 8-Bits", "Random"]
method draw(module: NoiseOscillatorModule, index: int): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Noise", index, COLOR_OSCILLATOR.uint32)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index)
    if(igSliderInt("Mode", module.noiseMode.addr, 0, 2, format = noiseTypes[module.noiseMode])):
        module.noiseMode = clamp(module.noiseMode, 0, noiseTypes.len - 1)
        synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index)
    igEndColumns()
    return

proc drawModule*(index: int): void {.inline.} =
    let module = synthContext.moduleList[index]
    if(module == nil): return

    module.draw(index)
    
    # echo typeof(module)
    # if(module of SineOscillatorModule):
    #     module.SineOscillatorModule.draw(index)

    # elif(module of TriangleOscillatorModule):
    #     module.TriangleOscillatorModule.draw(index)

    # elif(module of SawOscillatorModule):
    #     module.SawOscillatorModule.draw(index)

    # elif(module of SquareOscillatorModule):
    #     module.SquareOscillatorModule.draw(index)

    # elif(module of FmodModule):
    #     module.FmodModule.draw(index)

    # elif(module of FmProModule):
    #     module.FmProModule.draw(index)

    # elif(module of MixerModule):
    #     module.MixerModule.draw(index)

    # elif(module of AverageModule):
    #     module.AverageModule.draw(index)

    # elif(module of AmplifierModule):
    #     module.AmplifierModule.draw(index)

    # elif(module of AbsoluterModule):
    #     module.AbsoluterModule.draw(index)

    # elif(module of RectifierModule):
    #     module.RectifierModule.draw(index)

    # elif(module of ClipperModule):
    #     module.ClipperModule.draw(index)
    
    # elif(module of InverterModule):
    #     module.InverterModule.draw(index)

    # elif(module of PdModule):
    #     module.PdModule.draw(index)

    # elif(module of SyncModule):
    #     module.SyncModule.draw(index)

    # elif(module of MorphModule):
    #     module.MorphModule.draw(index)

    # elif(module of ExpModule):
    #     module.ExpModule.draw(index)

    # elif(module of OverflowModule):
    #     module.OverflowModule.draw(index)

    # elif(module of MultModule):
    #     module.MultModule.draw(index)

    # elif(module of DualWaveModule):
    #     module.DualWaveModule.draw(index)

    # elif(module of PhaseModule):
    #     module.PhaseModule.draw(index)

    # elif(module of WaveFoldModule):
    #     module.WaveFoldModule.draw(index)

    # elif(module of WaveMirrorModule):
    #     module.WaveMirrorModule.draw(index)

    # elif(module of DcOffsetModule):
    #     module.DcOffsetModule.draw(index)

    # elif(module of ChordModule):
    #     module.ChordModule.draw(index)

    # elif(module of FeedbackModule):
    #     module.FeedbackModule.draw(index)

    # elif(module of DownsamplerModule):
    #     module.DownsamplerModule.draw(index)

    # elif(module of QuantizerModule):
    #     module.QuantizerModule.draw(index)

    # elif(module of OutputModule):
    #     module.OutputModule.draw(index)

    # elif(module of LfoModule):
    #     module.LfoModule.draw(index)

    # elif(module of SoftClipModule):
    #     module.SoftClipModule.draw(index)

    # elif(module of WaveFolderModule):
    #     module.WaveFolderModule.draw(index)

    # elif(module of SplitterModule):
    #     module.SplitterModule.draw(index)