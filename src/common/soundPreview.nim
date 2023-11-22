import sdl2
import sdl2/audio
import globals
import ../kurumiX/synthesizer/synth
import ../kurumi3/synth/kurumi3synth
import math
import piano
import genericSynth

var phase: float64 = 0.0
const
    toneHz   = 440
    sampleHz = 48000

proc phaseAcc(length: int): float64 =
    let freqTable = float64(sampleHz) / float64(length)
    let playfreq = pianoKeys[((pianState.octave)*12)+int32(pianState.key)] / freqTable
    phase = (phase.float64 + playfreq.float64) mod float64(length)
    return (phase mod float64(length))

proc wavetable*(userData: pointer, stream: ptr uint8, length: int32) {.cdecl.} =
    var synth: GenericSynth = nil
    case synthMode:
    of KURUMI_3:
        synth = kurumi3SynthContext
    of KURUMI_X:
        synth = synthContext
    else:
        discard
    # if synth == nil: return
    let buf = cast[ptr UncheckedArray[int16]](stream)
    if(synth == nil or not pianState.isOn):
        for i in 0..<(length shr 1):
            buf[i] = 0.int16
    else:
        for i in 0..<(length shr 1):
            let ind = phaseAcc(synth.synthInfos.waveDims.x).int32
            var sample = synth.outputInt[ind mod synth.synthInfos.waveDims.x].float64
            sample = sample * (32000 / float64(synth.synthInfos.waveDims.y))
            let s2 = ((sample - 16000) * pianState.volume).int16
            buf[i] = s2

    if(pianState.isPressed and pianState.seqMode > 0):
        if(pianState.seqMode == 1):
            synth.synthInfos.macroFrame.inc
            if(synth.synthInfos.macroFrame > synth.synthInfos.macroLen):
                synth.synthInfos.macroFrame = synth.synthInfos.macroLen - 1
                pianState.isPressed = false
            synth.synthesize()
        else:
            synth.synthInfos.macroFrame.inc
            if(synth.synthInfos.macroFrame > synth.synthInfos.macroLen):
                synth.synthInfos.macroFrame = 0
            synth.synthesize()

proc initAudio*() =
    sdl2.init(0)

    var specs = AudioSpec(
        freq: sampleHz,
        format: AUDIO_S16,
        channels: 1,
        samples: 2048,
        callback: wavetable
    )

    discard openAudio(specs.addr, nil)
    pauseAudio(0)