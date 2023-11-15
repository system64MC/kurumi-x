import kurumi3Adsr
import ../synth/globals
import ../synth/adsr
import ../synth/kurumi3Synth
import ../synth/serialization
import kurumi3History
import imgui

let
    filterNames = ["None".cstring, "Biquad Lowpass", "Biquad Highpass", "Biquad Bandpass", "Biquad Bandstop", "Biquad Allpass"]

proc drawFiltersWindow*(): void {.inline.} =
    igBegin("Filter")
    if(igCombo("Filter Type", kurumi3SynthContext.selectedFilter.addr, filterNames[0].addr, filterNames.len.int32)):
        kurumi3SynthContext.synthesize()
        registerHistoryEvent("Change filter type")

    if(kurumi3SynthContext.selectedFilter == 0): igBeginDisabled()
    
    if(igSliderFloat("Cutoff", kurumi3SynthContext.filterAdsr.peak.addr, 0, 1)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change filter cutoff")
    if(igSliderInt("Pitch", kurumi3SynthContext.pitch.addr, 0, 96)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change filter pitch")
    if(igSliderFloat("Q", kurumi3SynthContext.q.addr, 0.250, 4)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change filter resonance")

    if(igSliderInt("Envelope Mode", kurumi3SynthContext.filterAdsr.mode.addr, 0, envModes.len - 1, envModes[kurumi3SynthContext.filterAdsr.mode], ImGuiSliderFlags.AlwaysClamp)):
        kurumi3SynthContext.synthesize()
    if(igIsItemDeactivated()):
        registerHistoryEvent("Change envelope mode")
    if(kurumi3SynthContext.filterAdsr.mode > 0): igSeparator()
    kurumi3SynthContext.filterAdsr.addr.drawEnvelope(1)


    if(kurumi3SynthContext.selectedFilter == 0): igEndDisabled()
    igEnd()