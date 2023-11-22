import ../../common/globals
import ../../common/utils
import ../synth/kurumi3Synth
import ../synth/serialization
import kurumi3History
import imgui

const
    OSC_W = 256.0
    OSC_H = 64.0

let envModes* = ["None".cstring, "ADSR", "Custom"]
proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)
proc drawEnvelope*(adsrPtr: ptr Adsr, maxPeak: float32): void {.inline.} =
    igBeginChild("envSettings")
    var space: ImVec2
    igGetContentRegionMaxNonUDT(space.addr)
    # space.y = max(space.y, 64)
    let ratio = ((space.x) / 256.0).float64
    case adsrPtr.mode:
    of 0: discard
    of 1:
        # igBeginChild("env", ImVec2(x: OSC_W + 8, y: OSC_H + 4), true)
        igBeginChild("env", ImVec2(x: space.x, y: OSC_H + 4), true)
        var position = ImVec2()
        igGetWindowPosNonUDT(position.addr)
        var dl = igGetWindowDrawList()

        # Attack and peak1
        dl.addLine(
            ImVec2(x: position.x + 4 , y: position.y + 64.0f-adsrPtr.start*(64f / maxPeak) + 2),
            ImVec2(x: position.x + 4 + (adsrPtr.attack.float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.peak*(64f / maxPeak) + 2),
            0xFF_FF_FF_FF.uint32
        )

        # Decay and sustain
        dl.addLine(
            ImVec2(x: position.x + 4 + (adsrPtr.attack.float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.peak*(64f / maxPeak) + 2),
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.sustain*(64f / maxPeak) + 2),
            0xFF_FF_FF_FF.uint32
        )

        # Attack2 and peak2
        dl.addLine(
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.sustain*(64f / maxPeak) + 2),
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.peak2*(64f / maxPeak) + 2),
            0xFF_FF_FF_FF.uint32
        )

        # Decay2 and Sustain2
        dl.addLine(
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.peak2*(64f / maxPeak) + 2),
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
            0xFF_FF_FF_FF.uint32
        )

        # Sustain2
        dl.addLine(
            ImVec2(x: position.x + 4 + ((adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
            ImVec2(x: position.x + 4 + ((256).float32 / 1) * ratio, y: position.y + 64.0f-adsrPtr.sustain2*(64f / maxPeak) + 2),
            0xFF_FF_FF_FF.uint32
        )
        
        igEndChild()

        if(igSliderFloat("Start", adsrPtr.start.addr, 0, maxPeak)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Start")

        if(igSliderInt("Attack", adsrPtr.attack.addr, 0, 256)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Attack")

        if(igSliderFloat("Peak", adsrPtr.peak.addr, 0, maxPeak)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Peak")

        if(igSliderInt("Decay", adsrPtr.decay.addr, 0, 256)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Decay")

        if(igSliderFloat("Sus", adsrPtr.sustain.addr, 0, maxPeak)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Sustain")

        if(igSliderInt("Attack 2", adsrPtr.attack2.addr, 0, 256)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Attack 2")

        if(igSliderFloat("Peak 2", adsrPtr.peak2.addr, 0, maxPeak)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Peak 2")

        if(igSliderInt("Decay 2", adsrPtr.decay2.addr, 0, 256)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Decay 2")

        if(igSliderFloat("Sus 2", adsrPtr.sustain2.addr, 0, maxPeak)):
            kurumi3synthContext.synthesize()
        if(igIsItemDeactivated()):
            registerHistoryEvent("Edit ADSR Sustain 2")

        igText(("Keyframes : " & $(adsrPtr.attack + adsrPtr.decay + adsrPtr.attack2 + adsrPtr.decay2)).cstring)
    of 2:
        igBeginChild("Macro", ImVec2(x: space.x, y: 64 + 4), true, flags = ImGuiWindowFlags.AlwaysAutoResize)
        var position = ImVec2()
        igGetWindowPosNonUDT(position.addr)
        var dl = igGetWindowDrawList()

        for i in 0..<256:
            let x1 = i.float64
            let x2 = (i + 1).float64
            var sample = adsrPtr.mac[min(i, adsrPtr.mac.len - 1)].float32 / 4
            var sample1 = adsrPtr.mac[min(i + 1, adsrPtr.mac.len - 1)].float32 / 4
            dl.addLine(
                position + ImVec2(x: i.float32 * ratio + 4, y: 64 - sample + 2),    
                position + ImVec2(x: (i.float32 + 1) * ratio + 4, y: 64 - sample1 + 2),
                0xFF_4B_4B_C8.uint32    
            )
        igEndChild()
        var str = (adsrPtr.macString)
        str.setLen((adsrPtr.macString.len) + 1024)
        var strC = str.cstring
        if(igInputText("Envelope", strC, str.len.uint32 + 1024 + 1)):
            adsrPtr.macString = $strC
            adsrPtr.refreshAdsr()
            kurumi3SynthContext.synthesize()
            registerHistoryEvent("Edit Envelope macro")
    else: discard
    
    igEndChild()