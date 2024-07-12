import imgui
import piano
import genericSynth

let noteTable = ["A".cstring, "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
let seqMode = ["None".cstring, "One shot", "Loop"]

proc drawPiano*(synth: GenericSynth) {.inline.} =
    igBegin("Piano")
    igSliderInt("Seq. Mode", pianState.seqMode.addr, 0, 2, flags = ImGuiSliderFlags.AlwaysClamp, format = seqMode[pianState.seqMode])
    igSliderInt("Octave", pianState.octave.addr, 0, 7, flags = ImGuiSliderFlags.AlwaysClamp)
    if(igBeginTable("keyboard", 13)):
        igTableNextColumn()
        for i in 0..<12:
            if(igButton(noteTable[i], ImVec2(x: 30, y: 40))):
                pianState.key = i.int32
                pianState.isPressed = true
                if(pianState.seqMode > 0):
                    synth.synthInfos.macroFrame = 0
                    synth.synthesize()
            igTableNextColumn()
        igEndTable()
    igEnd()