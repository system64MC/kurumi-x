import json
import globals
import kurumi3synth
import operator
import ../../synthesizer/utils/utils
import stew/base64
import constants

proc seqToString(sequence: seq[byte]): tuple[data: string, min: byte, max: byte] =
    var str = ""
    var min = 0'u8
    var max = 0'u8
    for v in sequence:
        str &= (($v) & " ")
        if v > max:
            max = v
    return (str, min, max)

# TODO : Fix the min-max wavetable bug

proc loadKvp*(myJson: string) = 
    let jsonNode = parseJson(myJson)
    let ctx = kurumi3SynthContext
    # general parameters
    ctx.synthInfos.waveDims = VecI32(
        x: jsonNode["Synth"]["WaveLen"].getInt(32).int32,
        y: jsonNode["Synth"]["WaveHei"].getInt(31).int32
    )
    ctx.synthInfos.macroLen = jsonNode["Synth"]["MacLen"].getInt(64).int32
    ctx.synthInfos.macroFrame = jsonNode["Synth"]["Macro"].getInt(63).int32

    ctx.smoothWin = jsonNode["Synth"]["SmoothWin"].getInt(0).int32
    ctx.gain = jsonNode["Synth"]["Gain"].getFloat(1).float32
    ctx.synthInfos.oversample = jsonNode["Synth"]["Oversample"].getInt(4).int32
    let filtEnabled = (jsonNode["Synth"]["FilterEnabled"].getBool(false)).int32
    ctx.selectedFilter = (jsonNode["Synth"]["FilterType"].getInt(0) + 1).int32 * filtEnabled
    ctx.filterAdsr.peak = jsonNode["Synth"]["Cutoff"].getFloat(0).float32
    ctx.pitch = jsonNode["Synth"]["Pitch"].getInt(0).int32
    ctx.q = jsonNode["Synth"]["Resonance"].getFloat(0).float32
    ctx.filterAdsr.mode = jsonNode["Synth"]["FilterAdsrEnabled"].getBool(false).int32
    ctx.filterAdsr.start = jsonNode["Synth"]["FilterStart"].getFloat(0).float32
    ctx.filterAdsr.attack = jsonNode["Synth"]["FilterAttack"].getInt(0).int32
    ctx.filterAdsr.decay = jsonNode["Synth"]["FilterDecay"].getFloat(0).int32
    ctx.filterAdsr.sustain = jsonNode["Synth"]["FilterSustain"].getFloat(0).float32
    ctx.filterAdsr.mac = @[255]
    ctx.filterAdsr.macString = "255"
    ctx.normalize = (
        jsonNode["Synth"]["Normalize"].getBool(false).int32 +
        jsonNode["Synth"]["NewNormalizeBehavior"].getBool(false).int32
    )

    # matrix
    for i in 0..<NB_OPS:
        for j in 0..<NB_OPS:
            let idx = (i * NB_OPS) + j
            if(i >= 4 or j >= 4): 
                ctx.modMatrix[idx] = 0.0
                continue
            ctx.modMatrix[idx] = jsonNode["Synth"]["ModMatrix"][i][j].getBool(false).float32

    # outputs
    for i in 0..<4:
        ctx.opOuts[i] = jsonNode["Synth"]["OpOutputs"][i].getFloat(0).float32
    for i in 4..<NB_OPS:
        ctx.opOuts[i] = 0

    # operators
    for i in 0..<4:
        let opNode = jsonNode["Synth"]["Operators"][i]
        let op = ctx.operators[i]

        op.volAdsr.peak = opNode["Tl"].getFloat(0).float32
        op.volAdsr.start = opNode["Adsr"]["Start"].getFloat(0).float32
        op.volAdsr.attack = opNode["Adsr"]["Attack"].getInt(0).int32
        op.volAdsr.decay = opNode["Adsr"]["Decay"].getInt(0).int32
        op.volAdsr.sustain = opNode["Adsr"]["Sustain"].getFloat(0).float32
        op.volAdsr.mode = (
            (1 + opNode["UseCustomVolEnv"].getBool(false).int32) *
            opNode["IsEnvelopeEnabled"].getBool(false).int32
        )
        op.reverseWaveform = opNode["Reverse"].getBool(false)
        op.waveform = opNode["WaveformId"].getInt(0).int32
        op.mult = opNode["Mult"].getInt(0).int32
        op.phase = opNode["Phase"].getFloat(0).float32
        op.detune = opNode["Detune"].getInt(0).int32
        op.feedback = opNode["Feedback"].getFloat(0).float32
        
        op.volAdsr.mac = Base64Pad.decode(opNode["VolEnv"].getStr("/w=="))
        var wData = op.volAdsr.mac.seqToString()
        op.volAdsr.macString = wData.data
        
        op.phaseEnv.mode = 2 * opNode["Feedback"].getBool(false).int32
        op.phaseEnv.mac = Base64Pad.decode(opNode["PhaseEnv"].getStr("AA=="))
        wData = op.phaseEnv.mac.seqToString()
        op.phaseEnv.macString = wData.data

        op.wavetable = Base64Pad.decode(opNode["Wavetable"].getStr("EBkeHx4dGhkZHB8cEgsKDREUFhQPBgACBgUDAQAAAQQ="))
        wData = op.wavetable.seqToString()
        op.waveStr = wData.data
        op.waveMin = wData.min
        op.waveMax = wData.max
        
        op.morphWave = Base64Pad.decode(opNode["MorphWave"].getStr("EBQPCwsYHh8cFAoCAAMFABAfGhwfHRULAwABBxQUEAs="))
        wData = op.morphWave.seqToString()
        op.morphStr = wData.data
        op.morphMin = wData.min
        op.morphMax = wData.max
        
        op.interpolation = opNode["Interpolation"].getInt(0).int32
        op.morphEnvelope.mode = opNode["Morphing"].getBool(false).int32
        op.morphEnvelope.attack = opNode["MorphTime"].getInt(0).int32
        op.morphEnvelope.peak = op.morphEnvelope.mode.float32
        op.modMode = opNode["ModMode"].getInt(0).int32
        op.pwmEnv.peak = opNode["DutyCycle"].getFloat(0).float32
        op.pwmEnv.start = opNode["PwmAdsr"]["Start"].getFloat(0).float32
        op.pwmEnv.attack = opNode["PwmAdsr"]["Attack"].getInt(0).int32
        op.pwmEnv.decay = opNode["PwmAdsr"]["Decay"].getInt(0).int32
        op.pwmEnv.sustain = opNode["PwmAdsr"]["Sustain"].getFloat(0).float32
        op.pwmEnv.mode = opNode["PwmAdsrEnabled"].getBool(false).int32
        op.pwmEnv.mac = @[128]
        op.pwmEnv.macString = "128"

    for i in 4..<NB_OPS:
        ctx.operators[i] = Operator()
