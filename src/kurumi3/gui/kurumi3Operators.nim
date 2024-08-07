import imgui
import strformat
import math
import ../../common/globals
import ../../common/constants
import ../../common/utils
import ../synth/operator
import ../synth/kurumi3Synth
import ../synth/serialization
import kurumi3Adsr
import kurumi3History

let
    modModes = ["FM".cstring, "OR", "XOR", "AND", "NAND", "ADD", "SUB", "MUL", "MIN", "MAX", "EXP", "ROOT"]
    

proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

proc drawPwm(opId: int) {.inline.} =
    igBeginChild("pwm")
    if(igSliderFloat("Duty Cycle", kurumi3SynthContext.operators[opId].pwmEnv.peak.addr, 0, 1)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit duty cycle")

    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].pwmEnv.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].pwmEnv.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit PWM. Env. Mode")

    if(kurumi3SynthContext.operators[opId].pwmEnv.mode > 0): igSeparator()

    (kurumi3SynthContext.operators[opId].pwmEnv.addr).drawEnvelope(1)

    igEndChild()

proc drawExp(opId: int) {.inline.} =
    igBeginChild("Exp")
    if(igSliderFloat("Exponent", kurumi3SynthContext.operators[opId].expEnv.peak.addr, 0, 16)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit exponent")

    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].expEnv.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].expEnv.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Exp. Env. Mode")

    if(kurumi3SynthContext.operators[opId].expEnv.mode > 0): igSeparator()

    (kurumi3SynthContext.operators[opId].expEnv.addr).drawEnvelope(16)

    igEndChild()

let distModes = ["Squish".cstring, "Sync", "Phase"]
proc drawDist(opId: int) {.inline.} =
    igBeginChild("Distortion")
    if(igSliderInt("Dist. Mode", kurumi3SynthContext.operators[opId].distMode.addr, 0, distmodes.len - 1, distModes[kurumi3SynthContext.operators[opId].distMode], flags = ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Dist. Mode")
        
    if(igSliderFloat(distModes[kurumi3SynthContext.operators[opId].distMode], kurumi3SynthContext.operators[opId].distAdsr.peak.addr, 0, 1, flags = ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Dist")

    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].distAdsr.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].distAdsr.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Dist. Env. Mode")

    if(kurumi3SynthContext.operators[opId].distAdsr.mode > 0): igSeparator()

    (kurumi3SynthContext.operators[opId].distAdsr.addr).drawEnvelope(1)

    igEndChild()

let waveforms = [
    "Sine".cstring,
    "Rect. Sine",
    "Abs. Sine",
    "Quarter Sine",
    "Squished Sine",
    "Squished Rect. Sine",
    "Squished Abs. Sine",
    "Pulse",
    "Rectified Pulse",
    "Saw",
    "Rect. Saw",
    "Abs. Saw",
    "Cubed Saw",
    "Rect. Cubed Saw",
    "Abs. Cubed Saw",
    "Cubed Sine",
    "Rect. Cubed Sine",
    "Abs. Cubed Sine",
    "Quarter Cubed Sine",
    "Squished Cubed Sine",
    "Squi. Rect. Cubed Sine",
    "Squi. Abs. Cubed Sine",
    "Triangle",
    "Rect. Triange",
    "Abs. Triangle",
    "Quarter Triangle",
    "Squished Triangle",
    "Rect. Squished Triangle",
    "Abs. Squished Triangle",
    "Cubed Triangle",
    "Rect. Cubed Triangle",
    "Abs. Cubed Triangle",
    "Quarter Cubed Triangle",
    "Squi. Cubed Triangle",
    "Squi. Rect. Cubed Triangle",
    "Squi. Abs. Cubed Triangle",
    "Noise (1 bit, LFSR)",
    "Noise (8 bits, LFSR)",
    "Noise (Random)",
    "Custom",
    "Rect. Custom",
    "Abs. Custom",
    "Cubed Custom",
    "Rect. Cubed Custom",
    "Abs. Cubed Custom"
]

proc drawMorphing(opId: int) {.inline.} =
    igBeginChild("morphing")
    
    var str = (kurumi3SynthContext.operators[opId].morphStr)
    str.setLen((str.len) + 1024)
    var strC = str.cstring
    if(igInputText("Morph Wavetable", strC, str.len.uint32 + 1024 + 1)):
        kurumi3SynthContext.operators[opId].waveStr = $strC
        kurumi3SynthContext.operators[opId].refreshWaveform(MORPH)
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Edit wavetable")
    
    if(igSliderFloat("Morph", kurumi3SynthContext.operators[opId].morphEnvelope.peak.addr, 0, 1)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit morph")

    if(igCombo("Waveform", kurumi3SynthContext.operators[opId].morphWaveform.addr, waveforms[0].addr, waveforms.len.int32)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Change waveform")

    let op = kurumi3SynthContext.operators[opId]
    igBeginChild("wave", border = true, flags = ImGuiWindowFlags.AlwaysAutoResize)
    var space: ImVec2
    igGetContentRegionMaxNonUDT(space.addr)
    # space.y = max(space.y, 64)
    let ratio = ((space.x) / 256.0).float64
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()

    for i in 0..<256:
        let x1 = i.float64 * ratio
        let x2 = (i + 1).float64 * ratio
        # var sample = waveFuncs[op.waveform](op, i.float64 / 256.0, kurumi3SynthContext.synthInfos) * -(space.y / 2) + 0
        var sample = op.oscillate(i.float64 / 256.0, kurumi3SynthContext.synthInfos) * -(64 / 2) + 0
        if(op.reverseWaveform): sample *= -1.0
        dl.addRectFilled(
            position + ImVec2(x: x1 + 4, y: (64 / 2) + 2),    
            position + ImVec2(x: x2 + 4, y: sample + (64 / 2) + 2),
            0xFF_4B_4B_C8.uint32    
        )
    igEndChild()

    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].morphEnvelope.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].volAdsr.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit morph Env. Mode")
    
    (kurumi3SynthContext.operators[opId].morphEnvelope.addr).drawEnvelope(1)
    igEndChild()

proc drawPhases(opId: int) {.inline.} =
    igBeginChild("phases")
    if(igSliderFloat("Phase", kurumi3SynthContext.operators[opId].phase.addr, 0, 1)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit Phase")

    if(igSliderInt("Detune", kurumi3SynthContext.operators[opId].detune.addr, -16, 16)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit detune")
    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].phaseEnv.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].volAdsr.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit phase Env. Mode")
    (kurumi3SynthContext.operators[opId].phaseEnv.addr).drawEnvelope(1)
    # if(igCheckbox("Use custom phase envelope", kurumi3SynthContext.operators[opId].usePhaseEnv.addr)):
        # discard
    igEndChild()


proc drawVolumes(opId: int) {.inline.} =
    igBeginChild("volumes")
    if(igSliderFloat("Mod. Depth", kurumi3SynthContext.operators[opId].volAdsr.peak.addr, 0, 4)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit mod. depth")

    # if(igCheckbox("Use Enveloppe on volume", kurumi3SynthContext.operators[opId].useVolEnv.addr)):
    #     discard

    # if(not kurumi3SynthContext.operators[opId].useVolEnv.bool): igBeginDisabled()

    # if(igCheckbox("Use custom vol. env. instead of ADSR", kurumi3SynthContext.operators[opId].useCustomVolEnv.addr)):
    #     discard
    if(igSliderInt("Envelope Mode", kurumi3SynthContext.operators[opId].volAdsr.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.operators[opId].volAdsr.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Edit mod. depth Env. mode")
    
    if(kurumi3SynthContext.operators[opId].volAdsr.mode > 0): igSeparator()

    kurumi3SynthContext.operators[opId].volAdsr.addr.drawEnvelope(4)

    igEndChild()

proc drawGenerals(opId: int) {.inline.} =
    igBeginChild("generals")
    if(igCombo("Mod. Mode", kurumi3SynthContext.operators[opId].modMode.addr, modModes[0].addr, modModes.len.int32)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Change mod. mode")

    if(igSliderFloat("Feedback", kurumi3SynthContext.operators[opId].feedback.addr, 0, 4)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change feedback")

    if(igSliderInt("Mult", kurumi3SynthContext.operators[opId].mult.addr, 0, 32)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change mult")
    igEndChild()

proc drawOperatorsControls(opId: int) {.inline.} =
    
    if(igBeginTabBar("operatorsTabs")):
        if(igBeginTabItem("General")):
            drawGenerals(opId)
            igEndTabItem()

        if(igBeginTabItem("Volume")):
            drawVolumes(opId)
            igEndTabItem()

        if(igBeginTabItem("Phase")):
            drawPhases(opId)
            igEndTabItem()

        if(igBeginTabItem("Morph")):
            drawMorphing(opId)
            igEndTabItem()

        if(igBeginTabItem("PWM")):
            drawPwm(opId)
            igEndTabItem()

        if(igBeginTabItem("Dist")):
            drawDist(opId)
            igEndTabItem()

        if(igBeginTabItem("Exp")):
            drawExp(opId)
            igEndTabItem()

        igEndTabBar()




let interpolations = ["None".cstring, "Linear", "Cosine", "Cubic"]
proc drawWaveformSettings(opId: int) {.inline.} =
    if(igCombo("Waveform", kurumi3SynthContext.operators[opId].waveform.addr, waveforms[0].addr, waveforms.len.int32)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Change waveform")
    if(igCheckbox("Reverse waveform", kurumi3SynthContext.operators[opId].reverseWaveform.addr)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Reverse waveform")

    if(kurumi3SynthContext.operators[opId].waveform < waveforms.len - 1 - 6): igBeginDisabled()
    if(igCombo("Interpolation", kurumi3SynthContext.operators[opId].interpolation.addr, interpolations[0].addr, interpolations.len.int32)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Change interpolation")
    if(kurumi3SynthContext.operators[opId].waveform < waveforms.len - 1 - 6): igEndDisabled()
    let op = kurumi3SynthContext.operators[opId]
    
    var str = (op.waveStr)
    str.setLen((str.len) + 1024)
    var strC = str.cstring
    if(igInputText("Wavetable", strC, str.len.uint32 + 1024 + 1)):
        op.waveStr = $strC
        op.refreshWaveform()
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Edit wavetable")

    # igBeginChild("wave", ImVec2(x: space.x, y: space.y), true, flags = ImGuiWindowFlags.AlwaysAutoResize)
    igBeginChild("wave", border = true, flags = ImGuiWindowFlags.AlwaysAutoResize)
    var space: ImVec2
    igGetContentRegionMaxNonUDT(space.addr)
    # space.y = max(space.y, 64)
    let ratio = ((space.x) / 256.0).float64
    var position = ImVec2()
    igGetWindowPosNonUDT(position.addr)
    var dl = igGetWindowDrawList()

    for i in 0..<256:
        let x1 = i.float64 * ratio
        let x2 = (i + 1).float64 * ratio
        # var sample = waveFuncs[op.waveform](op, i.float64 / 256.0, kurumi3SynthContext.synthInfos) * -(space.y / 2) + 0
        var sample = op.oscillate(i.float64 / 256.0, kurumi3SynthContext.synthInfos) * -(space.y / 2) + 0
        if(op.reverseWaveform): sample *= -1.0
        dl.addRectFilled(
            position + ImVec2(x: x1 + 4, y: (space.y / 2) + 2),    
            position + ImVec2(x: x2 + 4, y: sample + (space.y / 2) + 2),
            0xFF_4B_4B_C8.uint32    
        )
    igEndChild()
    
        # synthContext.synthesize()
        # registerHistoryEvent("Edit Wavetable OSC. Wave")


proc drawOperatorsWindow*(): void {.inline.} =
    igBegin("Operators", flags = ImGuiWindowFlags.NoScrollbar)
    if(igBeginTabBar("operatorsTabs")):
        for i in 0..<NB_OPS:

            if(igBeginTabItem((fmt"OP {i + 1}".cstring))):
                igBeginTable((fmt"OpTable{i + 1}".cstring), 2)
                igTableNextColumn()
                drawOperatorsControls(i)
                igTableNextColumn()
                igBeginChild("waveformChild")
                drawWaveformSettings(i)
                igEndChild()
                
                igEndTable()
                igEndTabItem()
                
        igEndTabBar()
    igEnd()