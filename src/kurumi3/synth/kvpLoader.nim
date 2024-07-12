import json
import ../../common/globals
import kurumi3Synth
import operator
import ../../common/utils
import stew/base64
import constants

proc seqToString(sequence: seq[byte]): tuple[data: string, min: byte, max: byte] =
    var str = ""
    var min = 0'u8
    var max = 0'u8
    if sequence.len == 0: return ("", 0, 0)
    for v in sequence:
        str &= (($v) & " ")
        if v > max:
            max = v
    return (str, min, max)


proc loadKvpFile*(myJson: string) = 
    let jsonNode = parseJson(myJson)
    let ctx = kurumi3SynthContext
    # general parameters
    ctx.synthInfos.waveDims = VecI32(
        x: min(jsonNode["Synth"]["WaveLen"].getInt(32).int32, 4096),
        y: jsonNode["Synth"]["WaveHei"].getInt(31).int32
    )
    ctx.synthInfos.macroLen = jsonNode["Synth"]["MacLen"].getInt(64).int32
    ctx.synthInfos.macroFrame = jsonNode["Synth"]["Macro"].getInt(63).int32

    ctx.smoothWin = jsonNode["Synth"]["SmoothWin"].getInt(0).int32
    ctx.gain = jsonNode["Synth"]["Gain"].getFloat(1).float32
    ctx.synthInfos.oversample = min(jsonNode["Synth"]["Oversample"].getInt(4).int32, 8)
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
    ctx.filterAdsr.attack2 = 0
    ctx.filterAdsr.peak2 = ctx.filterAdsr.sustain
    ctx.filterAdsr.decay2 = 0
    ctx.filterAdsr.sustain2 = ctx.filterAdsr.sustain
    ctx.filterAdsr.mac = @[255]
    ctx.filterAdsr.macString = "255"
    ctx.normalize = (
        jsonNode["Synth"]["Normalize"].getBool(false).int32 +
        jsonNode["Synth"]["NewNormalizeBehavior"].getBool(false).int32
    )
    if(ctx.normalize > 0): ctx.normalize += 5

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
        op.volAdsr.attack2 = 0
        op.volAdsr.peak2 = op.volAdsr.sustain
        op.volAdsr.decay2 = 0
        op.volAdsr.sustain2 = op.volAdsr.sustain
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
        op.morphEnvelope.sustain = op.morphEnvelope.peak
        op.morphEnvelope.attack2 = 0
        op.morphEnvelope.peak2 = op.morphEnvelope.sustain
        op.morphEnvelope.decay2 = 0
        op.morphEnvelope.sustain2 = op.morphEnvelope.sustain
        op.modMode = opNode["ModMode"].getInt(0).int32
        op.pwmEnv.peak = opNode["DutyCycle"].getFloat(0).float32
        op.pwmEnv.start = opNode["PwmAdsr"]["Start"].getFloat(0).float32
        op.pwmEnv.attack = opNode["PwmAdsr"]["Attack"].getInt(0).int32
        op.pwmEnv.decay = opNode["PwmAdsr"]["Decay"].getInt(0).int32
        op.pwmEnv.sustain = opNode["PwmAdsr"]["Sustain"].getFloat(0).float32
        op.pwmEnv.attack2 = 0
        op.pwmEnv.peak2 = op.pwmEnv.sustain
        op.pwmEnv.decay2 = 0
        op.pwmEnv.sustain2 = op.pwmEnv.sustain
        op.pwmEnv.mode = opNode["PwmAdsrEnabled"].getBool(false).int32
        op.pwmEnv.mac = @[128]
        op.pwmEnv.macString = "128"
        
        op.distAdsr = Adsr(mac: @[255], macString: "255", peak: 1.0)
        op.distMode = 0

        op.expEnv = Adsr(mac: @[255], macString: "255", peak: 1.0)

    for i in 4..<NB_OPS:
        ctx.operators[i] = Operator()


    kurumi3synthContext.synthesize()

proc loadKvp2File*(myJson: string) = 
    let jsonNode = parseJson(myJson)
    let ctx = kurumi3SynthContext
    # general parameters
    ctx.synthInfos.waveDims = VecI32(
        x: min(jsonNode["Synth"]["infos"]["waveDims"]["x"].getInt(32).int32, 4096),
        y: jsonNode["Synth"]["infos"]["waveDims"]["y"].getInt(31).int32
    )
    ctx.synthInfos.macroLen = jsonNode["Synth"]["infos"]["macroLen"].getInt(64).int32
    ctx.synthInfos.macroFrame = jsonNode["Synth"]["infos"]["macroFrame"].getInt(63).int32
    ctx.synthInfos.oversample = min(jsonNode["Synth"]["infos"]["oversample"].getInt(4).int32, 8)

    ctx.smoothWin = jsonNode["Synth"]["smoothWin"].getInt(0).int32
    ctx.gain = jsonNode["Synth"]["gain"].getFloat(1).float32
    ctx.selectedFilter = jsonNode["Synth"]["selectedFilter"].getInt(0).int32
    
    ctx.filterAdsr.mode = min(jsonNode["Synth"]["filterAdsr"]["mode"].getInt(0).int32, 2)
    ctx.filterAdsr.peak = jsonNode["Synth"]["filterAdsr"]["peak"].getFloat(0).float32
    ctx.filterAdsr.start = jsonNode["Synth"]["filterAdsr"]["start"].getFloat(0).float32
    ctx.filterAdsr.attack = jsonNode["Synth"]["filterAdsr"]["attack"].getInt(0).int32
    ctx.filterAdsr.decay = jsonNode["Synth"]["filterAdsr"]["decay"].getFloat(0).int32
    ctx.filterAdsr.sustain = jsonNode["Synth"]["filterAdsr"]["sustain"].getFloat(0).float32
    ctx.filterAdsr.attack2 = jsonNode["Synth"]["filterAdsr"]["attack2"].getInt(0).int32
    ctx.filterAdsr.peak2 = jsonNode["Synth"]["filterAdsr"]["peak2"].getFloat(0).float32
    ctx.filterAdsr.decay2 = jsonNode["Synth"]["filterAdsr"]["decay2"].getFloat(0).int32
    ctx.filterAdsr.sustain2 = jsonNode["Synth"]["filterAdsr"]["sustain2"].getFloat(0).float32
    let elems = jsonNode["Synth"]["filterAdsr"]["mac"].getElems()
    ctx.filterAdsr.mac = newSeq[byte](elems.len)
    for i in 0..<elems.len:
        ctx.filterAdsr.mac[i] = elems[i].getInt(0).byte
    ctx.filterAdsr.macString = ctx.filterAdsr.mac.seqToString().data
    
    ctx.pitch = jsonNode["Synth"]["pitch"].getInt(0).int32
    ctx.q = jsonNode["Synth"]["q"].getFloat(0).float32
    ctx.normalize = jsonNode["Synth"]["normalize"].getInt(0).int32

    let matrixElems = jsonNode["Synth"]["modMatrix"].getElems()
    for i in 0..<matrixElems.len:
        ctx.modMatrix[i] = matrixElems[i].getFloat(0)

    let outputElems = jsonNode["Synth"]["opOuts"].getElems()
    for i in 0..<outputElems.len:
        ctx.opOuts[i] = outputElems[i].getFloat(0)

    let opElems = jsonNode["Synth"]["operators"].getElems()
    for i in 0..<opElems.len:
        if i >= 8: break
        let opNode = opElems[i]
        ctx.operators[i].modMode = opNode["modMode"].getInt(0).int32
        ctx.operators[i].feedback = opNode["feedback"].getFloat(0).float32
        ctx.operators[i].mult = opNode["mult"].getInt(0).int32
        ctx.operators[i].detune = opNode["detune"].getInt(0).int32
        ctx.operators[i].waveform = opNode["waveform"].getInt(0).int32
        ctx.operators[i].reverseWaveform = opNode["reverseWaveform"].getBool(false)
        ctx.operators[i].interpolation = opNode["interpolation"].getInt(0).int32

        ctx.operators[i].volAdsr.mode = min(opNode["volAdsr"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].volAdsr.start = opNode["volAdsr"]["start"].getFloat(0).float32
        ctx.operators[i].volAdsr.attack = opNode["volAdsr"]["attack"].getInt(0).int32
        ctx.operators[i].volAdsr.peak = opNode["volAdsr"]["peak"].getFloat(0).float32
        ctx.operators[i].volAdsr.decay = opNode["volAdsr"]["decay"].getFloat(0).int32
        ctx.operators[i].volAdsr.sustain = opNode["volAdsr"]["sustain"].getFloat(0).float32
        ctx.operators[i].volAdsr.attack2 = opNode["volAdsr"]["attack2"].getInt(0).int32
        ctx.operators[i].volAdsr.peak2 = opNode["volAdsr"]["peak2"].getFloat(0).float32
        ctx.operators[i].volAdsr.decay2 = opNode["volAdsr"]["decay2"].getFloat(0).int32
        ctx.operators[i].volAdsr.sustain2 = opNode["volAdsr"]["sustain2"].getFloat(0).float32
        let volElems = opNode["volAdsr"]["mac"].getElems()
        ctx.operators[i].volAdsr.mac = newSeq[byte](volElems.len)
        for j in 0..<volElems.len:
            ctx.operators[i].volAdsr.mac[j] = volElems[j].getInt(0).byte
        ctx.operators[i].volAdsr.macString = ctx.operators[i].volAdsr.mac.seqToString().data

        ctx.operators[i].morphEnvelope.mode = min(opNode["morphEnvelope"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].morphEnvelope.start = opNode["morphEnvelope"]["start"].getFloat(0).float32
        ctx.operators[i].morphEnvelope.attack = opNode["morphEnvelope"]["attack"].getInt(0).int32
        ctx.operators[i].morphEnvelope.peak = opNode["morphEnvelope"]["peak"].getFloat(0).float32
        ctx.operators[i].morphEnvelope.decay = opNode["morphEnvelope"]["decay"].getFloat(0).int32
        ctx.operators[i].morphEnvelope.sustain = opNode["morphEnvelope"]["sustain"].getFloat(0).float32
        ctx.operators[i].morphEnvelope.attack2 = opNode["morphEnvelope"]["attack2"].getInt(0).int32
        ctx.operators[i].morphEnvelope.peak2 = opNode["morphEnvelope"]["peak2"].getFloat(0).float32
        ctx.operators[i].morphEnvelope.decay2 = opNode["morphEnvelope"]["decay2"].getFloat(0).int32
        ctx.operators[i].morphEnvelope.sustain2 = opNode["morphEnvelope"]["sustain2"].getFloat(0).float32
        let morphElems = opNode["morphEnvelope"]["mac"].getElems()
        ctx.operators[i].morphEnvelope.mac = newSeq[byte](morphElems.len)
        for j in 0..<morphElems.len:
            ctx.operators[i].morphEnvelope.mac[j] = morphElems[j].getInt(0).byte
        ctx.operators[i].morphEnvelope.macString = ctx.operators[i].morphEnvelope.mac.seqToString().data

        ctx.operators[i].pwmEnv.mode = min(opNode["pwmEnv"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].pwmEnv.start = opNode["pwmEnv"]["start"].getFloat(0).float32
        ctx.operators[i].pwmEnv.attack = opNode["pwmEnv"]["attack"].getInt(0).int32
        ctx.operators[i].pwmEnv.peak = opNode["pwmEnv"]["peak"].getFloat(0).float32
        ctx.operators[i].pwmEnv.decay = opNode["pwmEnv"]["decay"].getFloat(0).int32
        ctx.operators[i].pwmEnv.sustain = opNode["pwmEnv"]["sustain"].getFloat(0).float32
        ctx.operators[i].pwmEnv.attack2 = opNode["pwmEnv"]["attack2"].getInt(0).int32
        ctx.operators[i].pwmEnv.peak2 = opNode["pwmEnv"]["peak2"].getFloat(0).float32
        ctx.operators[i].pwmEnv.decay2 = opNode["pwmEnv"]["decay2"].getFloat(0).int32
        ctx.operators[i].pwmEnv.sustain2 = opNode["pwmEnv"]["sustain2"].getFloat(0).float32
        let pwmElems = opNode["pwmEnv"]["mac"].getElems()
        ctx.operators[i].pwmEnv.mac = newSeq[byte](pwmElems.len)
        for j in 0..<pwmElems.len:
            ctx.operators[i].pwmEnv.mac[j] = pwmElems[j].getInt(0).byte
        ctx.operators[i].pwmEnv.macString = ctx.operators[i].pwmEnv.mac.seqToString().data

        ctx.operators[i].phaseEnv.mode = min(opNode["phaseEnv"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].phaseEnv.start = opNode["phaseEnv"]["start"].getFloat(0).float32
        ctx.operators[i].phaseEnv.attack = opNode["phaseEnv"]["attack"].getInt(0).int32
        ctx.operators[i].phaseEnv.peak = opNode["phaseEnv"]["peak"].getFloat(0).float32
        ctx.operators[i].phaseEnv.decay = opNode["phaseEnv"]["decay"].getFloat(0).int32
        ctx.operators[i].phaseEnv.sustain = opNode["phaseEnv"]["sustain"].getFloat(0).float32
        ctx.operators[i].phaseEnv.attack2 = opNode["phaseEnv"]["attack2"].getInt(0).int32
        ctx.operators[i].phaseEnv.peak2 = opNode["phaseEnv"]["peak2"].getFloat(0).float32
        ctx.operators[i].phaseEnv.decay2 = opNode["phaseEnv"]["decay2"].getFloat(0).int32
        ctx.operators[i].phaseEnv.sustain2 = opNode["phaseEnv"]["sustain2"].getFloat(0).float32
        let phaseElems = opNode["phaseEnv"]["mac"].getElems()
        ctx.operators[i].phaseEnv.mac = newSeq[byte](phaseElems.len)
        for j in 0..<phaseElems.len:
            ctx.operators[i].phaseEnv.mac[j] = phaseElems[j].getInt(0).byte
        ctx.operators[i].phaseEnv.macString = ctx.operators[i].phaseEnv.mac.seqToString().data

        ctx.operators[i].distMode = min(opNode["distMode"].getInt(0).int32, 2)
        ctx.operators[i].distAdsr.mode = min(opNode["distAdsr"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].distAdsr.start = opNode["distAdsr"]["start"].getFloat(0).float32
        ctx.operators[i].distAdsr.attack = opNode["distAdsr"]["attack"].getInt(0).int32
        ctx.operators[i].distAdsr.peak = opNode["distAdsr"]["peak"].getFloat(1).float32
        ctx.operators[i].distAdsr.decay = opNode["distAdsr"]["decay"].getFloat(0).int32
        ctx.operators[i].distAdsr.sustain = opNode["distAdsr"]["sustain"].getFloat(0).float32
        ctx.operators[i].distAdsr.attack2 = opNode["distAdsr"]["attack2"].getInt(0).int32
        ctx.operators[i].distAdsr.peak2 = opNode["distAdsr"]["peak2"].getFloat(0).float32
        ctx.operators[i].distAdsr.decay2 = opNode["distAdsr"]["decay2"].getFloat(0).int32
        ctx.operators[i].distAdsr.sustain2 = opNode["distAdsr"]["sustain2"].getFloat(0).float32
        let distElems = opNode["distAdsr"]["mac"].getElems()
        ctx.operators[i].distAdsr.mac = newSeq[byte](distElems.len)
        for j in 0..<distElems.len:
            ctx.operators[i].distAdsr.mac[j] = distElems[j].getInt(0).byte
        ctx.operators[i].distAdsr.macString = ctx.operators[i].distAdsr.mac.seqToString().data

        ctx.operators[i].expEnv.mode = min(opNode["expEnv"]["mode"].getInt(0).int32, 2)
        ctx.operators[i].expEnv.start = opNode["expEnv"]["start"].getFloat(0).float32
        ctx.operators[i].expEnv.attack = opNode["expEnv"]["attack"].getInt(0).int32
        ctx.operators[i].expEnv.peak = opNode["expEnv"]["peak"].getFloat(1).float32
        ctx.operators[i].expEnv.decay = opNode["expEnv"]["decay"].getFloat(0).int32
        ctx.operators[i].expEnv.sustain = opNode["expEnv"]["sustain"].getFloat(0).float32
        ctx.operators[i].expEnv.attack2 = opNode["expEnv"]["attack2"].getInt(0).int32
        ctx.operators[i].expEnv.peak2 = opNode["expEnv"]["peak2"].getFloat(0).float32
        ctx.operators[i].expEnv.decay2 = opNode["expEnv"]["decay2"].getFloat(0).int32
        ctx.operators[i].expEnv.sustain2 = opNode["expEnv"]["sustain2"].getFloat(0).float32
        let expElems = opNode["expEnv"]["mac"].getElems()
        ctx.operators[i].expEnv.mac = newSeq[byte](expElems.len)
        for j in 0..<expElems.len:
            ctx.operators[i].expEnv.mac[j] = expElems[j].getInt(0).byte
        ctx.operators[i].expEnv.macString = ctx.operators[i].expEnv.mac.seqToString().data

        let wtElems = opNode["wavetable"].getElems()
        ctx.operators[i].wavetable = newSeq[byte](wtElems.len)
        for j in 0..<wtElems.len:
            ctx.operators[i].wavetable[j] = wtElems[j].getInt(0).byte
        var wData = ctx.operators[i].wavetable.seqToString() 
        ctx.operators[i].waveStr = wData.data
        ctx.operators[i].waveMin = wData.min
        ctx.operators[i].waveMax = wData.max

        let mtElems = opNode["morphWave"].getElems()
        ctx.operators[i].morphWave = newSeq[byte](mtElems.len)
        for j in 0..<wtElems.len:
            ctx.operators[i].morphWave[j] = mtElems[j].getInt(0).byte
        wData = ctx.operators[i].morphWave.seqToString() 
        ctx.operators[i].morphStr = wData.data
        ctx.operators[i].morphMin = wData.min
        ctx.operators[i].morphMax = wData.max

    kurumi3synthContext.synthesize()
