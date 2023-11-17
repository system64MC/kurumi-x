import ../synthesizer/synth
import imgui
import std/typeinfo
import ../../common/globals
import ../../common/utils
import ../synthesizer/linkManagement
import ../synthesizer/synthesizeWave
import ../synthesizer/modules
import moduleCreateMenu
import history
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

let
    envModes = ["None".cstring, "ADSR", "Custom"]

proc drawTitleBar(text: cstring, index: int, color: uint32 = 0xFF000000.uint32, moduleList: var array[256, SynthModule]): void {.inline.} =
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
    if not(moduleList[index] of OutputModule):
        if(igButton("X", ImVec2(x: 16, y: 16))):
            deleteModule(index, moduleList)
            synthContext.synthesize()
            registerHistoryEvent("Delete module")
    igEndChild()
    igPopStyleColor()
    # igSetCursorPosY(y + 24)
    return



proc drawInputs(module: SynthModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    for i in 0..<module.inputs.len():
        if(igButton(("I##" & $i).cstring)):
            if(selectedLink.moduleIndex > -1 and selectedLink.pinIndex > -1):
                module.makeLink(index, i, moduleList)
                registerHistoryEvent("Create Link")
            else:
                module.breakLinksInput(i, moduleList)
                registerHistoryEvent("Break Link")
            synthContext.synthesize()

proc drawOutputs(module: SynthModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    for i in 0..<module.outputs.len():
        if(igButton(("O##" & $i).cstring)):
            if(module.outputs[i].moduleIndex > -1 or module.outputs[i].pinIndex > -1): module.breakLinksOutput(i, moduleList)
            selectedLink.moduleIndex = index.int16
            selectedLink.pinIndex = i.int16
            synthContext.synthesize()

const
    COLOR_NORMAL = 0xFF_FF_FF_FF.uint32
    COLOR_SATURATE = 0xFF_7F_7F_FF.uint32

proc drawOscilloscope(module: SynthModule, index: int, moduleList: array[256, SynthModule]): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, 0, moduleList, synthContext.synthInfos)
        if(sample > 1 or sample < -1): color = COLOR_SATURATE
        let x = (sample) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()

proc drawOscilloscopeOut(module: OutputModule, index: int, moduleList: array[256, SynthModule]): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    # if(module == nil): return
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, module.inputs[0].pinIndex, moduleList, synthContext.synthInfos)
        if(sample > 1 or sample < -1): color = COLOR_SATURATE
        let x = (sample) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()

proc drawOscilloscopeFMPro(module: FmProModule, index: int, moduleList: array[256, SynthModule]): void {.inline.} =
    igBeginChild("osc", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()
    for i in 0..<OSC_W.int:
        var color = COLOR_NORMAL
        let half = (OSC_H / 2)
        var sum = 0.0
        for pin in 0..<6:
            let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, pin, moduleList, synthContext.synthInfos)
            sum += sample
        if(sum > 1 or sum < -1): color = COLOR_SATURATE
        let x = (sum) * half
        dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
    igEndChild()


proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)
proc drawEnvelope(adsrPtr: ptr Adsr, maxPeak: float32): void {.inline.} =
    igBeginChild("envSettings")
    case adsrPtr.mode
    of 1:
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
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Start")

        if(igSliderInt("Attack", adsrPtr.attack.addr, 0, 256)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Attack")

        if(igSliderFloat("Peak", adsrPtr.peak.addr, 0, maxPeak)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Peak")

        if(igSliderInt("Decay", adsrPtr.decay.addr, 0, 256)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Decay")

        if(igSliderFloat("Sus", adsrPtr.sustain.addr, 0, maxPeak)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Sustain")

        if(igSliderInt("Attack 2", adsrPtr.attack2.addr, 0, 256)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Attack 2")

        if(igSliderFloat("Peak 2", adsrPtr.peak2.addr, 0, maxPeak)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Peak 2")

        if(igSliderInt("Decay 2", adsrPtr.decay2.addr, 0, 256)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Decay 2")

        if(igSliderFloat("Sus 2", adsrPtr.sustain2.addr, 0, maxPeak)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Sustain 2")
            
        igText(("Keyframes : " & $(adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2)).cstring)
    of 2:
        igBeginChild("Macro", ImVec2(x: 128 + 8, y: 64 + 4), true, flags = ImGuiWindowFlags.AlwaysAutoResize)
        var position = ImVec2()
        igGetWindowPosNonUDT(position.addr)
        var dl = igGetWindowDrawList()

        for i in 0..<128:
            let x1 = i.float64
            let x2 = (i + 1).float64
            var sample = adsrPtr.mac[min(i, adsrPtr.mac.len - 1)].float32 / 4
            var sample1 = adsrPtr.mac[min(i + 1, adsrPtr.mac.len - 1)].float32 / 4
            dl.addLine(
                position + ImVec2(x: i.float32 + 4, y: 64 - sample + 2),    
                position + ImVec2(x: i.float32 + 1 + 4, y: 64 - sample1 + 2),
                0xFF_4B_4B_C8.uint32    
            )
        igEndChild()
        var str = (adsrPtr.macString)
        str.setLen((adsrPtr.macString.len) + 1024)
        var strC = str.cstring
        if(igInputText("Envelope", strC, str.len.uint32 + 1024 + 1)):
            adsrPtr.macString = $strC
            adsrPtr.refreshAdsr()
            registerHistoryEvent("Edit Envelope macro")
        discard

        # igEndChild()
    else: discard
    igEndChild()
    
method draw(module: SynthModule, index: int, moduleList: var array[256, SynthModule]): void {.inline, base.} =
    
    # var vec = ImVec2()
    # igGetContentRegionAvailNonUDT(vec.addr)
    # drawTitleBar("DUMMY MODULE", index, COLOR_FM.uint32)
    # igColumns(3, nil, border = false)
    # igSetColumnOffset(0, 0)
    # drawInputs(module, index, moduleList)
    # igSetColumnOffset(1, 20)
    # igNextColumn()
    # module.drawOscilloscope(index, moduleList)
    # igSetColumnOffset(2, vec.x - 20)
    # igNextColumn()
    # drawOutputs(module, index, moduleList)
    # igEndColumns()
    return

method draw(module: FmodModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM", index, COLOR_FM.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

var selectedPopupModule: SynthModule = nil
var modalOpen = false

# proc drawModal*(): void {.inline.} =
#     # if(selectedPopupModule == nil): return
#     echo modalOpen
#     if(igBeginPopupModal("testAAAA", modalOpen.addr)):
#         igText("Amogus")
#         igEndPopup()
#     return

proc lerp(x, y, a: float32): float32 =
    return x*(1-a) + y*a  
method draw(module: FmProModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM Pro", index, COLOR_FM.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscopeFMPro(index, moduleList)

    # igBeginChild("matrix")

    # igBeginTable("opMatrix", 6)
    # for i in 0..<6:
    #     for j in 0..<6:
    #         igTableNextColumn()
    #         if(igCheckbox(("##op" & $i & $j).cstring, module.matrix[i][j].addr)):
    #             synthContext.synthesize()
    
    # igEndTable()


    if(igButton("Edit matrix")):
        igOpenPopup("Modulation Matrix")

    igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 1)
            
    if(igBeginPopupModal("Modulation Matrix", nil)):

        igBeginTable("opOsc", 8, flags = (ImGuiTableFlags.SizingFixedSame.int).ImGuiTableFlags)
        for a in 0..<8:
            igTableNextColumn()
            igText(("Operator " & $(a + 1)).cstring)
            igBeginChild(("##oscOp" & $a).cstring, ImVec2(x: OSC_W + 8, y: OSC_H + 4), true, ImGuiWindowFlags.NoResize)
            var position = ImVec2()
            igGetWindowPosNonUDT(position.addr)
            var dl = igGetWindowDrawList()
            for i in 0..<OSC_W.int:
                var color = COLOR_NORMAL
                let half = (OSC_H / 2)
                var sum = 0.0
                let sample = -module.synthesize(i.float64 * PI * 2 / OSC_W, a, moduleList, synthContext.synthInfos)
                sum += sample
                if(sum > 1 or sum < -1): color = COLOR_SATURATE
                let x = (sum) * half
                dl.addRectFilled(ImVec2(x: position.x + i.float64 + 4, y: position.y + half + 2), ImVec2(x: position.x + i.float64 + 1 + 4, y: position.y + half + x + 2), color)
            igEndChild()
        igEndTable()

        igText("Note : You can CTRL + Left click on a slider to edit the value manually.")
        igBeginTable("opMatrix", 8, flags = (ImGuiTableFlags.SizingFixedSame.int).ImGuiTableFlags)
        for i in 0..<8:
            for j in 0..<8:
                let index = i * 8 + j
                igTableNextColumn()
                igBeginChild(($index).cstring, ImVec2(x: 128, y: 40), true, ImGuiWindowFlags.NoResize)
                # let colGrab = igGetStyleColorVec4(ImGuiCol.SliderGrab)
                # let colActive = igGetStyleColorVec4(ImGuiCol.SliderGrabActive)
                # let bg = igGetStyleColorVec4(ImGuiCol.FrameBg)
                # let bgHover = igGetStyleColorVec4(ImGuiCol.FrameBgHovered)
                # let bgActive = igGetStyleColorVec4(ImGuiCol.FrameBgActive)

                # var h, s, v: float32
                # var h2, s2, v2: float32
                # var h3, s3, v3: float32
                # var h4, s4, v4: float32
                # var h5, s5, v5: float32

                # igColorConvertRGBtoHSV(colGrab.x, colGrab.y, colGrab.z, h.addr, s.addr, v.addr)
                # igColorConvertRGBtoHSV(colActive.x, colActive.y, colActive.z, h2.addr, s2.addr, v2.addr)
                # igColorConvertRGBtoHSV(bg.x, bg.y, bg.z, h3.addr, s3.addr, v3.addr)
                # igColorConvertRGBtoHSV(bgHover.x, bgHover.y, bgHover.z, h4.addr, s4.addr, v4.addr)
                # igColorConvertRGBtoHSV(bgActive.x, bgActive.y, bgActive.z, h5.addr, s5.addr, v5.addr)
                
                # let hc = h
                # let hc2 = h2
                # let hc3 = h3
                # let hc4 = h4
                # let hc5 = h5

                # # h = lerp(0, h, h * -(0 - (module.modMatrix[index] / 4)))
                # # h2 = lerp(0, h2, h2 * -(0 - (module.modMatrix[index] / 4)))
                # h = h - h * -(0 - (module.modMatrix[index] / 4))
                # h2 = h2 - h2 * -(0 - (module.modMatrix[index] / 4))
                # h3 = h3 - h3 * -(0 - (module.modMatrix[index] / 4))
                # h4 = h4 - h4 * -(0 - (module.modMatrix[index] / 4))
                # h5 = h5 - h5 * -(0 - (module.modMatrix[index] / 4))

                # var r, g, b: float32
                # var r2, g2, b2: float32
                # var r3, g3, b3: float32
                # var r4, g4, b4: float32
                # var r5, g5, b5: float32

                # igColorConvertHSVtoRGB(clamp(h , 0, hc ), s, v, r.addr, g.addr, b.addr)
                # igColorConvertHSVtoRGB(clamp(h2, 0, hc2), s2, v2, r2.addr, g2.addr, b2.addr)
                # igColorConvertHSVtoRGB(clamp(h3, 0, hc3), s3, v3, r3.addr, g3.addr, b3.addr)
                # igColorConvertHSVtoRGB(clamp(h4, 0, hc4), s4, v4, r4.addr, g4.addr, b4.addr)
                # igColorConvertHSVtoRGB(clamp(h5, 0, hc5), s5, v5, r5.addr, g5.addr, b5.addr)

                # igPushStyleColor(ImGuiCol.SliderGrab, ImVec4(
                #     x: r,
                #     y: g,
                #     z: b,
                #     w: colGrab.w
                #     ))

                # igPushStyleColor(ImGuiCol.SliderGrabActive, ImVec4(
                #     x: r2,
                #     y: g2,
                #     z: b2,
                #     w: colActive.w
                #     ))

                # igPushStyleColor(ImGuiCol.FrameBg, ImVec4(
                #     x: r3,
                #     y: g3,
                #     z: b3,
                #     w: bg.w
                #     ))
                
                # igPushStyleColor(ImGuiCol.FrameBgHovered, ImVec4(
                #     x: r4,
                #     y: g4,
                #     z: b4,
                #     w: bgHover.w
                #     ))

                # igPushStyleColor(ImGuiCol.FrameBgActive, ImVec4(
                #     x: r5,
                #     y: g5,
                #     z: b5,
                #     w: bgActive.w
                #     ))

                if(igSliderFloat(("##opSlider" & $i & $j).cstring, module.modMatrix[index].addr, 0, 4)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit FM Pro Modulation Matrix")
                # igPopStyleColor(5)
                igEndChild()
        
        igEndTable()

        if(igButton("Close")):
            igCloseCurrentPopup()
        igEndPopup()
    igPopStyleVar()

    # igEndChild()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: MixerModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Mixer", index, COLOR_MIXER.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: AverageModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Average", index, COLOR_MIXER.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SineOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Sine Oscillator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Sine OSC. Mult")
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Sine OSC. Phase")
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Sine OSC. Detune")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: TriangleOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Triangle Oscillator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Triangle OSC. Mult")
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Triangle OSC. Phase")
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Triangle OSC. Detune")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SawOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Saw Oscillator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Saw OSC. Mult")
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Saw OSC. Phase")
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Saw OSC. Detune")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SquareOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Pulse Oscillator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Pulse OSC. Mult")
        if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Pulse OSC. Phase")
        if(igSliderFloat("P. Width", module.dutyEnvelope.peak.addr, 0f, 1f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Pulse OSC. P. Width")
        if(igSliderInt("Detune", module.detune.addr, -32, 32)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Pulse OSC. Detune")
        if(igSliderInt("Envelope Mode", module.dutyEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.dutyEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Edit Pulse OSC. Env. Mode")
        igEndTabItem()
    if(module.dutyEnvelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.dutyEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

const interpolations: array[3, cstring] = ["Nearest".cstring, "Linear", "Cubic"]
method draw(module: WavetableOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wavetable Oscillator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Mult.", module.mult.addr, 0, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Wavetable OSC. Mult")
    if(igSliderFloat("Phase", module.phase.addr, 0f, 1f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Wavetable OSC. Phase")
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Wavetable OSC. Detune")

    var str = ($module.waveStr)
    str.setLen((module.waveStr.len) + 1024)
    var strC = str.cstring
    if(igInputText("Wavetable", strC, str.len.uint32 + 1024 + 1)):
        module.waveStr = $strC
        module.refreshWaveform()
        synthContext.synthesize()
        registerHistoryEvent("Edit Wavetable OSC. Wave")

    if(igSliderInt("Interpolation", module.interpolation.addr, 0, interpolations.len - 1, format = interpolations[module.interpolation])):
        module.interpolation = clamp(module.interpolation, 0, interpolations.len - 1)
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Wavetable OSC. Interpolation")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: CalculatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Calculator", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)

        var str = ($module.formula)
        str.setLen((module.formula.len) + 1024)
        var strC = str.cstring
        if(igInputTextMultiline("##0", strC, str.len.uint32 + 1024 + 1, size = ImVec2(x: 128, y: 100), flags = ImGuiInputTextFlags.AllowTabInput)):
            module.formula = $strC
            # module.refreshWaveform()
            synthContext.synthesize()
            registerHistoryEvent("Edit Calculator formula")

        if(igButton("Edit")):
            igOpenPopup("Formula editor")
            

        # igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 1)
        if(igBeginPopupModal("Formula editor", nil, flags = ImGuiWindowFlags.NoResize)):
            igSetWindowSize("Formula editor", ImVec2(x: 660, y: 550))
            igBeginTabBar("tabs2")
            if(igBeginTabItem("General##1")):
                igBeginTable("", 2)
                igTableNextColumn()
                igBeginChild("", ImVec2(x: 320+80, y: 460+20), flags = ImGuiWindowFlags.NoResize)
                if(igInputTextMultiline("##1", strC, str.len.uint32 + 1024 + 1, size = ImVec2(x: 320, y: 470), flags = ImGuiInputTextFlags.AllowTabInput)):
                    module.formula = $strC
                    # module.refreshWaveform()
                    synthContext.synthesize()
                    registerHistoryEvent("Edit Calculator formula")
                igEndChild()
                if(igButton("Close")):
                    igCloseCurrentPopup()
                igTableNextColumn()
                igBeginChild("#111")
                module.drawOscilloscope(index, moduleList)
                igBeginChild("", ImVec2(x: 320+80, y: 400), flags = ImGuiWindowFlags.NoResize)
                igText("Variables :")
                igText("x -> the current X value.")
                igText("a -> value returned by first pin.")
                igText("b -> value returned by second pin.")
                igText("c -> value returned by third pin.")
                igText("d -> value returned by fourth pin.")
                igText("fb -> previous result")
                igText("wl -> Length of final waveform")
                igText("wh -> Height of final waveform")
                
                igText("env -> Current envelope value")
                igText("est -> Envelope Start")
                igText("ea1 -> Envelope Attack 1")
                igText("ep1 -> Envelope Peak 1")
                igText("ed1 -> Envelope Decay 1")
                igText("es1 -> Envelope SUStain 1")
                igText("ea2 -> Envelope Attack 2")
                igText("ep2 -> Envelope Peak 2")
                igText("ed2 -> Envelope Decay 2")
                igText("es2 -> Envelope SUStain 2\n")

                igText("pi -> 3.1415...")
                igText("tau -> 2x pi")
                igText("e -> Euler's number")
                igText("flan -> Q.E.D. \"Ripples of 495 Years\"\n")

                igText("\nFunctions :")
                igText("synth(pin, x) -> synthesizes the previous\nmodule with a given pin and X value.")
                igText("avg(var1, var2,...) -> Return the average of\nall arguments.")
                igText("clamp(min, x, max) -> Clamp X between\nmin and max.")
                igText("sin(x) -> Returns the sine of X")
                igText("cos(x) -> Returns the cosine of X")
                igText("tan(x) -> Returns the tangent of X")
                igText("asin(x) -> Returns the arcsin of X")
                igText("acos(x) -> Returns the arccos of X")
                igText("atan(x) -> Returns the htan of X")
                igText("sinh(x) -> Returns the hsin of X")
                igText("cosh(x) -> Returns the hcos of X")
                igText("tanh(x) -> Returns the htan of X")
                igText("floor(x)")
                igText("ceil(x)")
                igText("ln(x)")
                igText("log10(x)")
                igText("log2(x)")
                igText("max(var1, var2, ...)")
                igText("min(var1, var2, ...)")
                igText("pow(x, y)")
                igText("exp(x)")
                igEndChild()
                igEndChild()
                igEndTable()
                igEndTabItem()
            if(igBeginTabItem("Envelope##1")):
                module.envelope.addr.drawEnvelope(4)
                igEndTabItem()
            igEndTabBar()
            igEndPopup()
        igEndTabItem()
    if(igBeginTabItem("Envelope")):
        module.envelope.addr.drawEnvelope(4)
        igEndTabItem()
    igEndTabBar()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return


method draw(module: WaveShaperModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Shaper", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)

        var str = ($module.formula)
        str.setLen((module.formula.len) + 1024)
        var strC = str.cstring
        if(igInputTextMultiline("##0", strC, str.len.uint32 + 1024 + 1, size = ImVec2(x: 128, y: 100), flags = ImGuiInputTextFlags.AllowTabInput)):
            module.formula = $strC
            # module.refreshWaveform()
            synthContext.synthesize()
            registerHistoryEvent("Edit Shaper formula")

        if(igButton("Edit")):
            igOpenPopup("Shaper editor")
            

        # igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 1)
        if(igBeginPopupModal("Shaper editor", nil, flags = ImGuiWindowFlags.NoResize)):
            igSetWindowSize("Shaper editor", ImVec2(x: 660, y: 550))
            igBeginTabBar("tabs2")
            if(igBeginTabItem("General##1")):
                igBeginTable("", 2)
                igTableNextColumn()
                igBeginChild("", ImVec2(x: 320+80, y: 420+20), flags = ImGuiWindowFlags.NoResize)
                if(igInputTextMultiline("##1", strC, str.len.uint32 + 1024 + 1, size = ImVec2(x: 320, y: 230), flags = ImGuiInputTextFlags.AllowTabInput)):
                    module.formula = $strC
                    # module.refreshWaveform()
                    synthContext.synthesize()
                    registerHistoryEvent("Edit Shaper formula")
                if(igSliderFloat("A", module.a.peak.addr, 0.0f, 4.0f)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit A value")
                if(igSliderFloat("B", module.b.peak.addr, 0.0f, 4.0f)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit B value")
                if(igSliderFloat("C", module.c.peak.addr, 0.0f, 4.0f)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit C value")
                if(igSliderFloat("D", module.d.peak.addr, 0.0f, 4.0f)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit D value")
                igBeginChild("func", ImVec2(x: 256, y: 256), true, ImGuiWindowFlags.NoResize)
                var dl = igGetWindowDrawList()
                var position = ImVec2()
                igGetWindowPosNonUDT(position.addr)

                for i in -5..25:
                    let r = 1.0/20.0
                    let a = r * i.float64
                    dl.addLine(
                        ImVec2(x: position.x + 32 + a * 192, y: position.y + 0),
                        ImVec2(x: position.x + 32 + a * 192, y: position.y + 256),
                        0xFF_7F_7F_7F.uint32,
                        1.0
                    )

                    dl.addLine(
                        ImVec2(x: position.x + 0, y: position.y + 32 + a * 192),
                        ImVec2(x: position.x + 256, y: position.y + 32 + a * 192),
                        0xFF_7F_7F_7F.uint32,
                        1.0
                    )
                # Drawing X and Y axis
                dl.addLine(
                    ImVec2(x: position.x + 0, y: position.y + 128),
                    ImVec2(x: position.x + 256, y: position.y + 128),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )
                dl.addLine(
                    ImVec2(x: position.x + 128, y: position.y + 0),
                    ImVec2(x: position.x + 128, y: position.y + 256),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )

                dl.addLine(
                    ImVec2(x: position.x + 128 - 4, y: position.y + 32),
                    ImVec2(x: position.x + 128 + 4, y: position.y + 32),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )
                dl.addLine(
                    ImVec2(x: position.x + 128 - 4, y: position.y + 256 - 32),
                    ImVec2(x: position.x + 128 + 4, y: position.y + 256 - 32),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )

                dl.addLine(
                    ImVec2(x: position.x + 32, y: position.y + 128 - 4),
                    ImVec2(x: position.x + 32, y: position.y + 128 + 4),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )
                dl.addLine(
                    ImVec2(x: position.x + 256 - 32, y: position.y + 128 - 4),
                    ImVec2(x: position.x + 256 - 32, y: position.y + 128 + 4),
                    0xFF_FF_FF_FF.uint32,
                    2.0
                )

                const STEP = 2.6 / 256.0

                var i = -1.3
                while i < 1.3:
                    let val = module.computeEval(i.float64, moduleList, synthContext.synthInfos)
                    let val2 = module.computeEval((i + STEP).float64, moduleList, synthContext.synthInfos)
                    # dl.addLine(
                    #     ImVec2(x: position.x + val * 256 + 128, y: position.y * 192),
                    #     ImVec2(x: position.x + val2 * 256 + 128, y: position.y * 192),
                    #     0xFF_FF_00_00.uint32,
                    #     2.0
                    # )
                    dl.addLine(
                        ImVec2(x: position.x + (i / STEP) + 128, y: position.y + 128 + -val * 96),
                        ImVec2(x: position.x + ((i + STEP) / STEP) + 128, y: position.y + 128 + -val2 * 96),
                        0xFF_FF_00_00.uint32,
                        2.0
                    )
                    i += STEP
                igEndChild()
                igEndChild()
                if(igButton("Close")):
                    igCloseCurrentPopup()
                igTableNextColumn()
                igBeginChild("#111")
                module.drawOscilloscope(index, moduleList)
                igBeginChild("", ImVec2(x: 320+80, y: 400), flags = ImGuiWindowFlags.NoResize)
                igText("Variables :")
                igText("x -> the current X value.")
                igText("a -> Variable A")
                igText("b -> Variable B")
                igText("c -> Variable C")
                igText("d -> Variable D")
                # igText("fb -> previous result")
                
                igText("pi -> 3.1415...")
                igText("tau -> 2x pi")
                igText("e -> Euler's number")
                igText("flan -> Q.E.D. \"Ripples of 495 Years\"\n")

                igText("\nFunctions :")
                igText("synth(pin, x) -> synthesizes the previous\nmodule with a given pin and X value.")
                igText("avg(var1, var2,...) -> Return the average of\nall arguments.")
                igText("clip(min, x, max) -> Clips X between\nmin and max.")
                igText("clamp(min, x, max) -> like clip, but with wrapping")
                igText("sin(x) -> Returns the sine of X")
                igText("cos(x) -> Returns the cosine of X")
                igText("tan(x) -> Returns the tangent of X")
                igText("asin(x) -> Returns the arcsin of X")
                igText("acos(x) -> Returns the arccos of X")
                igText("atan(x) -> Returns the htan of X")
                igText("sinh(x) -> Returns the hsin of X")
                igText("cosh(x) -> Returns the hcos of X")
                igText("tanh(x) -> Returns the htan of X")
                igText("sign(x) -> returns the sign of x")
                igText("floor(x)")
                igText("ceil(x)")
                igText("ln(x)")
                igText("log10(x)")
                igText("log2(x)")
                igText("max(var1, var2, ...)")
                igText("min(var1, var2, ...)")
                igText("pow(x, y)")
                igText("exp(x)")
                igText("quant(x, q) -> quantizes x with interval q")
                igText("quantToBits(x, q) -> quantizes x with \ninterval b Bits")
                igText("cheby(x, n) -> Chebyshev polynomials \nto the nth order")
                igText("if(c, t, f) -> if c != 0 returns t, \nelse returns f")
                igText("select(c, n, z, p) -> if c < 0 returns n, \nif c = 0 returns z\nif c > 0 returns p")
                igText("equal(x, y) -> returns 1 if x = y, else 0")
                igText("below(x, y) -> returns 1 if x < y, else 0")
                igText("above(x, y) -> returns 1 if x > y, else 0")
                igText("beloweq(x, y) -> returns 1 if x <= y, else 0")
                igText("aboveeq(x, y) -> returns 1 if x >= y, else 0")
                
                igText("and(x, y) -> returns 1 if x and y != 0, else 0")
                igText("or(x, y) -> returns 1 if x or y != 0, else 0")
                igText("xor(x, y) -> returns 1 if x xor y != 0, else 0")
                igText("not(x) -> returns 1 if x = 0, else 0")
                
                igText("deg(x) -> rad to deg")
                igText("rad(x) -> deg to rad")
                igEndChild()
                igEndChild()
                igEndTable()
                igEndTabItem()
            if(igBeginTabItem("Envelope")):
                if(igSliderInt("Envelope A Mode", module.a.mode.addr, 0, envModes.len - 1, envModes[module.a.mode], ImGuiSliderFlags.AlwaysClamp)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()): registerHistoryEvent("A edit Env. Mode" & $envModes[module.a.mode])
                if(igSliderInt("Envelope B Mode", module.b.mode.addr, 0, envModes.len - 1, envModes[module.b.mode], ImGuiSliderFlags.AlwaysClamp)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()): registerHistoryEvent("B edit Env. Mode" & $envModes[module.b.mode])
                if(igSliderInt("Envelope C Mode", module.c.mode.addr, 0, envModes.len - 1, envModes[module.c.mode], ImGuiSliderFlags.AlwaysClamp)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()): registerHistoryEvent("C edit Env. Mode" & $envModes[module.c.mode])
                if(igSliderInt("Envelope D Mode", module.d.mode.addr, 0, envModes.len - 1, envModes[module.d.mode], ImGuiSliderFlags.AlwaysClamp)):
                    synthContext.synthesize()
                if(igIsItemDeactivated()): registerHistoryEvent("D edit Env. Mode" & $envModes[module.d.mode])
                
                
                igBeginTabBar("envs")
                if(module.a.mode > 0):
                    if(igBeginTabItem("Env. A")):
                        igBeginChild("envA", border = true)
                        module.a.addr.drawEnvelope(4)
                        igEndChild()
                        igEndTabItem()
                if(module.b.mode > 0):
                    if(igBeginTabItem("Env. B")):
                        igBeginChild("envB", border = true)
                        module.b.addr.drawEnvelope(4)
                        igEndChild()
                        igEndTabItem()
                if(module.c.mode > 0):
                    if(igBeginTabItem("Env. C")):
                        igBeginChild("envC", border = true)
                        module.c.addr.drawEnvelope(4)
                        igEndChild()
                        igEndTabItem()
                if(module.d.mode > 0):
                    if(igBeginTabItem("Env. D")):
                        igBeginChild("envD", border = true)
                        module.d.addr.drawEnvelope(4)
                        igEndChild()
                        igEndTabItem()
                igEndTabBar()
                igEndTabItem()
            # if(igBeginTabItem("ADSR##1")):
            #     module.envelope.addr.drawEnvelope(4)
            #     igEndTabItem()
            igEndTabBar()
            igEndPopup()
        igEndTabItem()
        
    # if(igBeginTabItem("ADSR")):
    #     module.envelope.addr.drawEnvelope(4)
    #     igEndTabItem()
    igEndTabBar()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: AmplifierModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Amplifier", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Amp.", module.envelope.peak.addr, 0.0f, 4.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Amplifier volume")
        if(igSliderInt("Envelope Mode", module.envelope.mode.addr, 0, envModes.len - 1, envModes[module.envelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Amplifier Env. Mode" & $envModes[module.envelope.mode])
        igEndTabItem()
    if(module.envelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.envelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: AbsoluterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Absoluter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: RectifierModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Rectifier", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: InverterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Inverter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: ClipperModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Clipper", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderFloat("Max.", module.clipMax.addr, -4.0f, 4.0f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Clipper Max value")
    if(igSliderFloat("Min.", module.clipMin.addr, -4.0f, 4.0f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Clipper Min value")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: PdModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Phase Dist.", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("X Dist.", module.xEnvelope.peak.addr, 0.0f, 1.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit PD X distortion")
        if(igSliderFloat("Y Dist.", module.yEnvelope.peak.addr, 0.0f, 1.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit PD Y distortion")
        if(igSliderInt("X Envelope Mode", module.xEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.xEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("PD X Env. Mode " & $envModes[module.xEnvelope.mode])
        if(igSliderInt("Y Envelope Mode", module.yEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.yEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("PD Y Env. Mode " & $envModes[module.yEnvelope.mode])
        igEndTabItem()
    if(module.xEnvelope.mode > 0):
        if(igBeginTabItem("X Dist. Env.")):
            module.xEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    if(module.yEnvelope.mode > 0):
        if(igBeginTabItem("Y Dist. Env.")):
            module.yEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SyncModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Sync", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()    
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Sync.", module.envelope.peak.addr, 0.0f, 16.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Sync")
        if(igSliderInt("Envelope Mode", module.envelope.mode.addr, 0, envModes.len - 1, envModes[module.envelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Sync Edit Env. Mode" & $envModes[module.envelope.mode])
        igEndTabItem()
    if(module.envelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.envelope.addr.drawEnvelope(16)
            igEndTabItem()
    igSetColumnOffset(2, vec.x - 20)
    igEndTabBar()

    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: MorphModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Morpher", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Morph.", module.envelope.peak.addr, 0.0f, 1.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Morph")
        igEndTabItem()

        if(igSliderInt("Envelope Mode", module.envelope.mode.addr, 0, envModes.len - 1, envModes[module.envelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Morph edit Env. Mode" & $envModes[module.envelope.mode])

    if(module.envelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.envelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: ExpModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Exponenter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Exp.", module.envelope.peak.addr, 0.0f, 16.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Exp.")

        if(igSliderInt("Envelope Mode", module.envelope.mode.addr, 0, envModes.len - 1, envModes[module.envelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Exp. edit Env. Mode" & $envModes[module.envelope.mode])
        igEndTabItem()
    if(module.envelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.envelope.addr.drawEnvelope(16)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: MultModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Multiplier", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: DualWaveModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Dual Wave", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: PhaseModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Phase", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderFloat("Phase", module.phase.addr, 0.0f, 1.0f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Phase")
    if(igSliderInt("Detune", module.detune.addr, -32, 32)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Detune")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: WaveFoldModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Folding", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: WaveMirrorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Mirroring", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderFloat("Mirror", module.mirrorPlace.addr, 0.0f, 1.0f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Mirror position")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: DcOffsetModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("DC Offset", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderFloat("Offset", module.offset.addr, -4.0f, 4.0f)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit DC offset")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: ChordModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Chord", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igBeginChild("a")
    for i in 0..<module.mults.len:
        if(igSliderInt(("Mul " & $(i + 1)).cstring, module.mults[i].addr, 0, 32)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chord")
    igEndChild()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: FeedbackModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("FM Feedback", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Feedback", module.fbEnvelope.peak.addr, 0.0f, 4.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Feedback")

        if(igSliderInt("Envelope Mode", module.fbEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.fbEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("FB edit Env. Mode" & $envModes[module.fbEnvelope.mode])

        igEndTabItem()
    if(module.fbEnvelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.fbEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: FastFeedbackModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Fast FM Feedback", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Feedback", module.fbEnvelope.peak.addr, 0.0f, 4.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast FB")

        if(igSliderInt("Envelope Mode", module.fbEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.fbEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Fast FB edit Env. Mode" & $envModes[module.fbEnvelope.mode])

        igEndTabItem()
    if(module.fbEnvelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.fbEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: DownsamplerModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Downsample", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()

    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Downsample", module.downsampleEnvelope.peak.addr, 0.0f, 1.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Downsample")

        if(igSliderInt("Envelope Mode", module.downsampleEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.downsampleEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Downsample edit Env. Mode" & $envModes[module.downsampleEnvelope.mode])
        igEndTabItem()
    if(module.downsampleEnvelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.downsampleEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()
    
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: QuantizerModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Quantizer", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()

    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Quant.", module.quantizationEnvelope.peak.addr, 0.0f, 1.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Quantizer")

        if(igSliderInt("Envelope Mode", module.quantizationEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.quantizationEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Quant. edit Env. Mode" & $envModes[module.quantizationEnvelope.mode])

        igEndTabItem()
    if(module.quantizationEnvelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.quantizationEnvelope.addr.drawEnvelope(1)
            igEndTabItem()
    igEndTabBar()

    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: OutputModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Output", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscopeOut(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

const lfoWaves: array[5, cstring] = ["Sine".cstring, "Triangle", "Saw", "Square", "Custom"]
const lfoModes: array[2, cstring] = ["Vibrato", "Tremollo"]
method draw(module: LfoModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("LFO", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("type", module.lfoType.addr, 0, 4, format = lfoWaves[module.lfoType])):
        module.lfoType = clamp(module.lfoType, 0, lfoWaves.len - 1)
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit LFO Type")
    if(igSliderInt("mode", module.lfoMode.addr, 0, 1, format = lfoModes[module.lfoMode])):
        module.lfoMode = clamp(module.lfoMode, 0, lfoModes.len - 1)
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit LFO Mode")
    if(igSliderFloat("Intensity", module.intensity.addr, 0, 4)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit LFO Intensity")
    if(igSliderInt("Frequency", module.frequency.addr, 0, 16)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit LFO Frequency")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SoftClipModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Soft Clip", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

const foldTypes: array[3, cstring] = ["Sine".cstring, "LinFold", "Wrap"]
method draw(module: WaveFolderModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Wave Folder", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Type", module.waveFoldType.addr, 0, 2, format = foldTypes[module.waveFoldType])):
        module.waveFoldType = clamp(module.waveFoldType, 0, foldTypes.len - 1)
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Wavefolder type")
    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: SplitterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Splitter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: NormalizerModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Normalizer", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

const filterTypes: array[5, cstring] = ["Lowpass".cstring, "Highpass", "Bandpass", "Bandstop", "Allpass"]
method draw(module: BqFilterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Biquad Filter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index, moduleList)
        module.drawOscilloscope(index, moduleList)
        if(igSliderInt("Type", module.filterType.addr, 0, filterTypes.len - 1, format = filterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, filterTypes.len - 1)
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Biquad Type")
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Biquad Cutoff")
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Biquad Resonance")
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Biquad Pitch")

        if(igSliderInt("Cut. Envelope Mode", module.cutoffEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.cutoffEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Cut. edit Env. Mode" & $envModes[module.cutoffEnvelope.mode])

        if(igSliderInt("Res. Envelope Mode", module.qEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.qEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Res. edit Env. Mode" & $envModes[module.qEnvelope.mode])
        
        if(igCheckbox("Normalize", module.normalize.addr)):
            synthContext.synthesize()
            registerHistoryEvent("Biquad Normalize " & (if(module.normalize): "checked" else: "unchecked"))
        igEndChild()
        igEndTabItem()
    if(module.cutoffEnvelope.mode > 0):
        if(igBeginTabItem("Cut. Env.")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.qEnvelope.mode > 0):
        if(igBeginTabItem("Res. Env.")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: FastBqFilterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Fast Biquad Filter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index, moduleList)
        module.drawOscilloscope(index, moduleList)
        if(igSliderInt("Type", module.filterType.addr, 0, filterTypes.len - 1, format = filterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, filterTypes.len - 1)
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast BQ Type")
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast BQ Cutoff")
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast BQ Resonance")
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast BQ Pitch")

        if(igSliderInt("Cut. Envelope Mode", module.cutoffEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.cutoffEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Cut. edit Env. Mode" & $envModes[module.cutoffEnvelope.mode])

        if(igSliderInt("Res. Envelope Mode", module.qEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.qEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Res. edit Env. Mode" & $envModes[module.qEnvelope.mode])

        if(igCheckbox("Normalize", module.normalize.addr)):
            synthContext.synthesize()
            registerHistoryEvent("Fast BQ Normalize " & (if(module.normalize): "checked" else: "unchecked"))
        igEndChild()
        igEndTabItem()
    if(module.cutoffEnvelope.mode > 0):
        if(igBeginTabItem("Cut. Env.")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.qEnvelope.mode > 0):
        if(igBeginTabItem("Res. Env.")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return


const chFilterTypes: array[2, cstring] = ["Lowpass".cstring, "Highpass"]
method draw(module: ChebyshevFilterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Chebyshev Filter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index, moduleList)
        module.drawOscilloscope(index, moduleList)
        if(igSliderInt("Type", module.filterType.addr, 0, chFilterTypes.len - 1, format = chFilterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, chFilterTypes.len - 1)
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chebyshev Type")
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chebyshev Cutoff")
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chebyshev Resonance")
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chebyshev Pitch")
        if(igSliderInt("Order", module.order.addr, 0, 32)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Chebyshev Order")

        if(igSliderInt("Cut. Envelope Mode", module.cutoffEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.cutoffEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Cut. edit Env. Mode" & $envModes[module.cutoffEnvelope.mode])

        if(igSliderInt("Res. Envelope Mode", module.qEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.qEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Res. edit Env. Mode" & $envModes[module.qEnvelope.mode])

        if(igCheckbox("Normalize", module.normalize.addr)):
            synthContext.synthesize()
            registerHistoryEvent("Chebyshev Normalize" & (if(module.normalize): "checked" else: "unchecked"))
        igEndChild()
        igEndTabItem()
    if(module.cutoffEnvelope.mode > 0):
        if(igBeginTabItem("Cut. Env.")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.qEnvelope.mode > 0):
        if(igBeginTabItem("Res. Env.")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: FastChebyshevFilterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Fast Chebyshev Filter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    


    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        igBeginChild("child")
        module.drawOscilloscope(index, moduleList)
        module.drawOscilloscope(index, moduleList)
        if(igSliderInt("Type", module.filterType.addr, 0, chFilterTypes.len - 1, format = chFilterTypes[module.filterType])):
            module.filterType = clamp(module.filterType, 0, chFilterTypes.len - 1)
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast CH. Type")
        if(igSliderFloat("Cutoff", module.cutoffEnvelope.peak.addr, 0, 1)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast CH. Cutoff")
        if(igSliderFloat("Resonance", module.qEnvelope.peak.addr, 0, 4)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast CH. Resonance")
        if(igSliderInt("Pitch", module.note.addr, 0, 96)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast CH. Pitch")
        if(igSliderInt("Order", module.order.addr, 0, 32)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Fast CH. Order")


        if(igSliderInt("Cut. Envelope Mode", module.cutoffEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.cutoffEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Cut. edit Env. Mode" & $envModes[module.cutoffEnvelope.mode])

        if(igSliderInt("Res. Envelope Mode", module.qEnvelope.mode.addr, 0, envModes.len - 1, envModes[module.qEnvelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Res. edit Env. Mode" & $envModes[module.qEnvelope.mode])

        if(igCheckbox("Normalize", module.normalize.addr)):
            synthContext.synthesize()
            registerHistoryEvent("Fast CH. Normalize" & (if(module.normalize): "checked" else: "unchecked"))
        igEndChild()
        igEndTabItem()
    if(module.cutoffEnvelope.mode > 0):
        if(igBeginTabItem("Cut. Env.")):
            module.cutoffEnvelope.addr.drawEnvelope(1)
            igEndTabItem()

    if(module.qEnvelope.mode > 0):
        if(igBeginTabItem("Res. Env.")):
            module.qEnvelope.addr.drawEnvelope(4)
            igEndTabItem()
    igEndTabBar()

    # igText(foldTypes[module.waveFoldType])
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: UnisonModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Unison", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Unison", module.unison.addr, 0, 8)):
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Unison")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

const noiseTypes: array[3, cstring] = ["LSFR 1-Bit".cstring, "LSFR 8-Bits", "Random"]
method draw(module: NoiseOscillatorModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Noise", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    if(igSliderInt("Mode", module.noiseMode.addr, 0, 2, format = noiseTypes[module.noiseMode])):
        module.noiseMode = clamp(module.noiseMode, 0, noiseTypes.len - 1)
        synthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Noise Mode")
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: QuadWaveAssemblerModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Quad Wave Assembler", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return


const
    WIN_PAD2 = 8.0f
    CELL_PAD_X2 = 8.0f
    CELL_PAD_Y2 = 4.0f
    CELL_SIZE_X2 = 256.0f + CELL_PAD_X2
    CELL_SIZE_Y2 = 256.0f + CELL_PAD_Y2
    BUTTON_SIZE_Y2 = 24.0f

proc `/`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x / vec2.x, y: vec1.y / vec2.y)

var scrollPoint = ImVec2()

proc drawModuleBox*(boxModule: BoxModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    let module = boxModule.moduleList[index]
    if(module == nil): return

    module.draw(index, boxModule.moduleList)

method draw(module: BoxModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Box", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)

    var str = ($module.name)
    str.setLen(256)
    var strC = str.cstring
    if(igInputText("Box name", strC,256)):
        module.name = $strC

    let winName = "Edit Box : " & module.name
    if(igButton("Edit")):
        igOpenPopup(winName.cstring, ImGuiPopupFlags.AnyPopupLevel)
            
        # igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 1)
    if(igBegin(winName.cstring, nil)):
        var size: ImVec2
        igGetWindowSizeNonUDT(size.addr)
        if(size.x < 512):
            igSetWindowSize(winName.cstring, ImVec2(x: 512, y: size.y))
        if(size.y < 512):
            igSetWindowSize(winName.cstring, ImVec2(x: size.x, y: 512))
        if(igButton("Close")):
            igCloseCurrentPopup()
        
        if(igBeginTable("tableBox", 16, (ImGuiTableFlags.SizingFixedSame.int or ImGuiTableFlags.ScrollX.int or ImGuiTableFlags.ScrollY.int).ImGuiTableFlags)):
            for i in 0..<16:
                igTableNextRow()
                for j in 0..<16:
                    igTableNextColumn()
                    let bIndex = i * 16 + j
                    
                    igBeginChild(($bIndex).cstring, ImVec2(x: 256, y: 256), true, ImGuiWindowFlags.NoResize)
                    module.drawModuleBox(bIndex, module.moduleList)
                    # igButton(("x:" & $j & " y:" & $i).cstring, ImVec2(x: 256, y: 256))
                    igEndChild()
                    drawModuleCreationContextMenuBox(bIndex, module.moduleList, module.outputIndex, module)
                    # drawModuleCreationContextMenu(index)
                    if(igIsItemHovered()):
                        copyPasteOps(bIndex, module.moduleList, module.outputIndex, module)
                continue
            scrollPoint.x = igGetScrollX()
            scrollPoint.y = igGetScrollY()
            igEndTable()
        
    
        # Drawing links
        var dl = igGetWindowDrawList()
        var winPos = ImVec2()
        igGetWindowPosNonUDT(winPos.addr)
        for i in 0..<16:
            for j in 0..<16:
                let bIndex = i * 16 + j
                let module = module.moduleList[bIndex]
                if(module == nil): continue
                # echo("x : " & $j & " y: " & $i)
                for x in 0..<module.outputs.len():
                    let link = module.outputs[x]
                    if(link.moduleIndex < 0 or link.pinIndex < 0): continue
                    let destPosX = link.moduleIndex mod 16
                    let destPosY = link.moduleIndex div 16
                    let p1 = ImVec2(x: WIN_PAD2 - scrollPoint.x + CELL_SIZE_X2 * j.float32 + winPos.x + CELL_SIZE_X2 - 24, y: WIN_PAD2 - scrollPoint.y + CELL_SIZE_Y2 * (i.float32) + winPos.y + 60 + x.float32 * BUTTON_SIZE_Y2) 
                    let p2 = ImVec2(x: WIN_PAD2 - scrollPoint.x + CELL_SIZE_X2 * destPosX.float32 + winPos.x + WIN_PAD2 + 4, y: WIN_PAD2 - scrollPoint.y + CELL_SIZE_Y2 * destPosY.float32 + winPos.y + 60 + link.pinIndex.float32 * BUTTON_SIZE_Y2) 
                    # let p3 = p2 / p1
                    let halfX = (p2.x - p1.x) / 2

                    if(p1.x < p2.x):
                        dl.addBezierCubic(p1, p1 + ImVec2(x: halfX, y: 0), p2 + ImVec2(x: -halfX, y: 0), p2, 0x7F_00_FF_FF.uint32, 4)
                    else:
                        dl.addBezierCubic(p1, p1 + ImVec2(x: -halfX, y: 0), p2 + ImVec2(x: halfX, y: 0), p2, 0x7F_00_FF_FF.uint32, 4)
                    # dl.addBezierQuadratic(p1, p2, p3, ))

        # draw temporary link
        if(selectedLink.moduleIndex > -1 and selectedLink.pinIndex > -1):
            let destPosX = selectedLink.moduleIndex mod 16
            let destPosY = selectedLink.moduleIndex div 16
            let p1 = ImVec2(x: WIN_PAD2 - scrollPoint.x + CELL_SIZE_X2 * destPosX.float32 + winPos.x + CELL_SIZE_X2 - 24, y: WIN_PAD2 - scrollPoint.y + CELL_SIZE_Y2 * destPosY.float32 + winPos.y + 60 + selectedLink.pinIndex.float32 * BUTTON_SIZE_Y2) 
            var p2 = ImVec2()
            igGetMousePosNonUDT(p2.addr)
            let halfX = (p2.x - p1.x) / 2

            if(p1.x < p2.x):
                dl.addBezierCubic(p1, p1 + ImVec2(x: halfX, y: 0), p2 + ImVec2(x: -halfX, y: 0), p2, 0x7F_FF_00_00.uint32, 4)
            else:
                dl.addBezierCubic(p1, p1 + ImVec2(x: -halfX, y: 0), p2 + ImVec2(x: halfX, y: 0), p2, 0x7F_FF_00_00.uint32, 4)

            if(igIsMouseDoubleClicked(ImGuiMouseButton.Left)):
                selectedLink.moduleIndex = -1
                selectedLink.pinIndex = -1
        igEnd()
    # if(igSliderInt("Unison", module.unison.addr, 0, 8)):
        # synthContext.synthesize()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: AvgFilterModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Average Filter", index, COLOR_OSCILLATOR.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    igBeginTabBar("tabs")
    if(igBeginTabItem("General")):
        module.drawOscilloscope(index, moduleList)
        if(igSliderFloat("Window", module.envelope.peak.addr, 0.0f, 255.0f)):
            synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit Window")

        if(igSliderInt("Envelope Mode", module.envelope.mode.addr, 0, envModes.len - 1, envModes[module.envelope.mode], ImGuiSliderFlags.AlwaysClamp)):
            synthContext.synthesize()
        if(igIsItemDeactivated()): registerHistoryEvent("Avg. edit Env. Mode" & $envModes[module.envelope.mode])

        if(igCheckbox("Normalize", module.normalize.addr)):
            synthContext.synthesize()
            registerHistoryEvent("Avg. Filter Normalize " & (if(module.normalize): "checked" else: "unchecked"))
        igEndTabItem()
    if(module.envelope.mode > 0):
        if(igBeginTabItem("Envelope")):
            module.envelope.addr.drawEnvelope(255)
            igEndTabItem()
    igEndTabBar()
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

method draw(module: ExpPlusModule, index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    var vec = ImVec2()
    igGetContentRegionAvailNonUDT(vec.addr)
    drawTitleBar("Exponenter Plus", index, COLOR_FM.uint32, moduleList)
    igColumns(3, nil, border = false)
    igSetColumnOffset(0, 0)
    drawInputs(module, index, moduleList)
    igSetColumnOffset(1, 20)
    igNextColumn()
    module.drawOscilloscope(index, moduleList)
    igSetColumnOffset(2, vec.x - 20)
    igNextColumn()
    drawOutputs(module, index, moduleList)
    igEndColumns()
    return

proc drawModule*(index: int, moduleList: var array[256, SynthModule]): void {.inline.} =
    let module = synthContext.moduleList[index]
    if(module == nil): return

    module.draw(index, moduleList)