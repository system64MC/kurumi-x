import operator
# import adsr
import ../../common/synthInfos
import ../../common/genericSynth
import ../../common/constants
# import ../../common/globals
import ../../common/utils
# import constants

type
    Kurumi3Synth* = ref object of GenericSynth
        modMatrix*: array[NB_OPS * NB_OPS, float32]
        opOuts*: array[NB_OPS, float32]
        operators*: array[NB_OPS, Operator]
        # infos*: SynthInfos

        selectedFilter*: int32 = 0
        # cutoff*: float32 = 0.0
        pitch*: int32 = 0
        q*: float32 = 0
        # filterAdsrOn*: bool = false
        filterAdsr*: Adsr
        smoothWin*: int32 = 0
        gain*: float32 = 1
        # oversample*: int32 = 4
        normalize*: int32

        matrixSamples*: array[NB_OPS, float64]
        floatTempBuf*: array[4096 * 8, float64]
        tmpMin*: float64
        tmpMax*: float64

    Kurumi3SynthSerialize* = object
        modMatrix*: array[NB_OPS * NB_OPS, float32]
        opOuts*: array[NB_OPS, float32]
        operators*: array[NB_OPS, OperatorSerialize]

        selectedFilter*: int32 = 0
        # cutoff*: float32 = 0.0
        pitch*: int32 = 0
        q*: float32 = 0
        # filterAdsrOn*: bool = false
        filterAdsr*: AdsrSerialize
        smoothWin*: int32 = 0
        gain*: float32 = 1
        # oversample*: int32 = 4
        normalize*: int32
        infos: SynthInfosSerialize

    Kurumi3synthObjectSerialize* = object
        Format: string = "krul"
        Synth: Kurumi3SynthSerialize
        

    ModulationModes = enum
        FM,
        OR,
        XOR,
        AND,
        NAND,
        ADD,
        SUB,
        MUL,
        MIN,
        MAX,
        EXP,
        ROOT,

proc serializeSynth*(synth: Kurumi3Synth): Kurumi3synthObjectSerialize =
    return Kurumi3synthObjectSerialize(
    Synth: Kurumi3SynthSerialize(
        modMatrix: synth.modMatrix,
        opOuts: synth.opOuts,
        operators: [
            synth.operators[0].serializeOperator(),
            synth.operators[1].serializeOperator(),
            synth.operators[2].serializeOperator(),
            synth.operators[3].serializeOperator(),
            synth.operators[4].serializeOperator(),
            synth.operators[5].serializeOperator(),
            synth.operators[6].serializeOperator(),
            synth.operators[7].serializeOperator(),
        ],
        selectedFilter: synth.selectedFilter,
        pitch: synth.pitch,
        q: synth.q,
        filterAdsr: synth.filterAdsr.serializeAdsr(),
        smoothWin: synth.smoothWin,
        gain: synth.gain,
        normalize: synth.normalize,
        infos: synth.synthInfos.serializeSynthInfos()
    )
    )

import math
proc logicMod(op: Operator, x, modValue: float64, infos: SynthInfos): float64 =
    case op.modMode.ModulationModes:
    of FM:
        return op.oscillate(x+modValue+op.getFB(), infos) * op.volAdsr.doAdsr(infos.macroFrame)
    of OR:
        let a = int(round((modValue + 1) * 32767.5))
        let b = int(round(((op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)) + (1 * op.volAdsr.doAdsr(infos.macroFrame))) * 32767.5))
        return (float64(a or b) / 32767.5) - (1 * op.volAdsr.doAdsr(infos.macroFrame))
    of XOR:
        let a = int(round((modValue + 1) * 32767.5))
        let b = int(round(((op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)) + (1 * op.volAdsr.doAdsr(infos.macroFrame))) * 32767.5))
        return (float64(a xor b) / 32767.5) - (1 * op.volAdsr.doAdsr(infos.macroFrame))
    of AND:
        let a = int(round((modValue + 1) * 32767.5))
        let b = int(round(((op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)) + (1 * op.volAdsr.doAdsr(infos.macroFrame))) * 32767.5))
        return (float64(a and b) / 32767.5) - (1 * op.volAdsr.doAdsr(infos.macroFrame))
    of NAND:
        let a = int(round((modValue + 1) * 32767.5))
        let b = int(round(((op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)) + (1 * op.volAdsr.doAdsr(infos.macroFrame))) * 32767.5))
        return (float64(not (a and b)) / 32767.5) - (1 * op.volAdsr.doAdsr(infos.macroFrame))
    of ADD:
        return modValue + (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame))
    of SUB:
        return (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)) - modValue
    of MUL:
        return modValue * (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame))
    of MIN:
        return min(modValue, (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)))
    of MAX:
        return max(modValue, (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame)))
    of EXP:
        let a = (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame))
        return pow(abs(a), abs(modValue)).copySign(a)
    of ROOT:
        let a = (op.oscillate(x, infos) * op.volAdsr.doAdsr(infos.macroFrame))
        # let myPow = if(modValue == 0.0): (1.0/0.0000000001) else: (1.0/modValue)
        let myPow = (1.0/modValue)
        return pow(abs(a), abs(myPow)).copySign(a)

proc fm(synth: Kurumi3Synth, x: float64): float64 =
    var x = x / float64(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    for op1 in 0..<NB_OPS:
        var sum = 0.0
        for modulator in 0..<NB_OPS:
            sum += synth.matrixSamples[modulator] * synth.modMatrix[(op1 * NB_OPS) + modulator]
        synth.matrixSamples[op1] = synth.operators[op1].logicMod(x, sum, synth.synthInfos)
        synth.operators[op1].prev = synth.matrixSamples[op1]
    var output = 0.0
    for o in 0..<NB_OPS:
        output += synth.matrixSamples[o] * synth.opOuts[o].float64
    return output

proc resetFB*(synth: Kurumi3Synth) =
    for i in 0..<NB_OPS:
        synth.operators[i].curr = 0
        synth.operators[i].prev = 0
        synth.matrixSamples[i] = 0

proc smooth*(synth: Kurumi3Synth, len: int) =
    if(synth.smoothWin == 0): return
    for i in 0..<(len):
        var smp = 0.0
        for j in -synth.smoothWin..synth.smoothWin:
            smp += synth.outputFloat[(i + j) % (len)]
        let avg = smp / ((synth.smoothWin * 2) + 1).float64
        synth.floatTempBuf[i] = avg

    # synth.tmpMin = synth.floatTempBuf[0]
    # synth.tmpMax = synth.floatTempBuf[0]
    for i in 0..<(len):
        let smp = synth.floatTempBuf[i]
        synth.outputFloat[i] = smp


# ------------------- Filter ----------------

func notetofreq(n: float64): float64 =
    return 440 * pow(2, (n-69)/12)

type 
    BiquadFilter = object
        # order:                     int
        a0, a1, a2, b1, b2:        float64 # Factors
        filterCutoff, Q, peakGain: float64 # Cutoff, Q, and peak gain
        z1, z2:                    float64 # poles
        # A, w0, w1, w2, d1, d2:     []float64
        # ep:                        float64
    
    FilterType = enum
        NONE,
        LOWPASS,
        HIGHPASS,
        BANDPASS,
        BANDSTOP,
        ALLPASS,

func buildBQFilter(synth: Kurumi3Synth, cutoff: float64): BiquadFilter =
    var filter = BiquadFilter()
    let sampleRate = notetofreq(float64(synth.pitch)) * float64(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    var norm: float64 = 0.0
    var K = tan(PI * cutoff / sampleRate)
    case synth.selectedFilter.FilterType
    of NONE: return
    of LOWPASS:
        if synth.q == 0:
            norm = 0.0
        else:
            norm = 1 / (1 + K / float64(synth.q) + K*K)
        filter.a0 = K * K * norm
        filter.a1 = 2 * filter.a0
        filter.a2 = filter.a0
        filter.b1 = 2 * (K*K - 1) * norm
        if synth.q == 0:
            filter.b2 = 0
        else:
            filter.b2 = (1 - K/float64(synth.q) + K*K) * norm
    of HIGHPASS:
        if(synth.q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(synth.q) + K*K)
        filter.a0 = 1 * norm
        filter.a1 = -2 * filter.a0
        filter.a2 = filter.a0
        filter.b1 = 2 * (K*K - 1) * norm
        if(synth.q == 0):
            filter.b2 = 0
        else:
            filter.b2 = (1 - K/float64(synth.q) + K*K) * norm
    of BANDPASS:
        if(synth.q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(synth.q) + K*K)
        filter.a0 = K / float64(synth.q) * norm
        filter.a1 = 0
        filter.a2 = -filter.a0
        filter.b1 = 2 * (K*K - 1) * norm
        if(synth.q == 0):
            filter.b2 = 0
        else:
            filter.b2 = (1 - K/float64(synth.q) + K*K) * norm
    of BANDSTOP:
        if(synth.q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(synth.q) + K*K)
        filter.a0 = (1 + K*K) * norm
        filter.a1 = 2 * (K*K - 1) * norm
        filter.a2 = filter.a0
        filter.b1 = filter.a1
        if(synth.q == 0):
            filter.b2 = 0
        else:
            filter.b2 = (1 - K/float64(synth.q) + K*K) * norm
    of ALLPASS:
        let aa = (K - 1.0) / (K + 1.0)
        let bb = -cos(PI * cutoff / sampleRate)
        filter.a0 = -aa
        filter.a1 = bb * (1.0 - aa)
        filter.a2 = 1.0
        filter.b1 = filter.a1
        filter.b2 = filter.a0

    return filter

proc processBQFilter(bqFilter: var BiquadFilter, x: float64): float64 =
    let output = x*bqFilter.a0 + bqFilter.z1
    bqFilter.z1 = x*bqFilter.a1 + bqFilter.z2 - bqFilter.b1*output
    bqFilter.z2 = x*bqFilter.a2 - bqFilter.b2*output
    return output

proc filter(synth: Kurumi3Synth) =
    if(synth.selectedFilter == 0): return
    let sampleRate = notetofreq(float64(synth.pitch)) * float64(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    let myCutoff = min(sampleRate / 2, 5 * pow(10.0, float64(synth.filterAdsr.doAdsr(synth.synthInfos.macroFrame))*3))
    var filter = synth.buildBQFilter(myCutoff)
    for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample * PREWARM):
        discard filter.processBQFilter(synth.outputFloat[i mod (synth.synthInfos.waveDims.x * synth.synthInfos.oversample)])

    for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
        synth.outputFloat[i] =  filter.processBQFilter(synth.outputFloat[i])


proc normalize2*(synth: Kurumi3Synth, len: int) =
    var 
        min = synth.outputFloat[0]
        max = synth.outputFloat[0]

    for i in 0..<len:
        min = min(synth.outputFloat[i], min)
        max = max(synth.outputFloat[i], max)
    let goodMax = max(abs(min), max)
    if(goodMax == 0): return
    for i in 0..<len:
        synth.outputFloat[i] = synth.outputFloat[i] / goodMax

proc synthesizeNew(synth: Kurumi3Synth) =
    for x in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
        synth.outputFloat[x] = synth.fm(x.float)
    for x in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
        synth.outputFloat[x] = synth.fm(x.float)

    synth.filter()

    synth.smooth(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    
    for c in 0..<synth.synthInfos.waveDims.x:
        var res = 0.0
        for i in 0..<synth.synthInfos.oversample:
            res += synth.outputFloat[c * synth.synthInfos.oversample + i]
        res /= synth.synthInfos.oversample.float64
        synth.outputFloat[c] = res

    if(synth.normalize > 0):
        # synth.normalize2(synth.synthInfos.waveDims.x)
        var 
            min = synth.outputFloat[0]
            max = synth.outputFloat[0]

        for i in 0..<synth.synthInfos.waveDims.x:
            min = min(synth.outputFloat[i], min)
            max = max(synth.outputFloat[i], max)
        let goodMax = max(abs(min), max)
        if(goodMax != 0):
            for i in 0..<synth.synthInfos.waveDims.x:
                let smp = synth.outputFloat[i] / goodMax
                synth.outputFloat[i] = smp
                synth.outputInt[i] = (round((smp + 1) * (synth.synthInfos.waveDims.y.float64 / 2.0))).int32
        else:
            for i in 0..<synth.synthInfos.waveDims.x:
                let smp = synth.outputFloat[i]
                synth.outputInt[i] = (round((smp + 1) * (synth.synthInfos.waveDims.y.float64 / 2.0))).int32
    else:
        for i in 0..<(synth.synthInfos.waveDims.x):
            let smp = clamp(synth.outputFloat[i], -1, 1)
            synth.outputFloat[i] = smp
            synth.outputInt[i] = (round((smp + 1) * (synth.synthInfos.waveDims.y.float64 / 2.0))).int32
    

proc synthesizeOld(synth: Kurumi3Synth) =
    for x in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
        synth.outputFloat[x] = synth.fm(x.float)
    for x in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
        synth.outputFloat[x] = synth.fm(x.float)

    synth.filter()

    synth.smooth(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    
    case synth.normalize:
    of 0:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            synth.outputFloat[i] = clamp(synth.outputFloat[i], -1, 1)
    of 1:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            synth.outputFloat[i] = (2.0/(1 +  pow(E, (-2 * synth.outputFloat[i])))) - 1
    of 2:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            synth.outputFloat[i] = sin(synth.outputFloat[i])
    of 3:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            let a = synth.outputFloat[i] * 0.25 + 0.75
            let r = a % 1
            synth.outputFloat[i] = abs(r * -4.0 + 2.0) - 1.0
    of 4:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            var a = synth.outputFloat[i]
            if(a > 1 or a < -1):
                a = ((a + 1) % 2) - 1
            synth.outputFloat[i] = a
    of 5:
        synth.normalize2(synth.synthInfos.waveDims.x * synth.synthInfos.oversample)
    else:
        for i in 0..<(synth.synthInfos.waveDims.x * synth.synthInfos.oversample):
            synth.outputFloat[i] = clamp(synth.outputFloat[i], -1, 1)
            
    for c in 0..<synth.synthInfos.waveDims.x:
        var res = 0.0
        for i in 0..<synth.synthInfos.oversample:
            res += synth.outputFloat[c * synth.synthInfos.oversample + i]
        res /= synth.synthInfos.oversample.float64
        synth.outputInt[c] = (round((res + 1) * (synth.synthInfos.waveDims.y.float64 / 2.0))).int32

method synthesize*(synth: Kurumi3Synth) {.gcsafe.} =
    synth.resetFB()
    echo synth.synthInfos.oversample
    if(synth.normalize < 6):
        synth.synthesizeOld()
    else:
        synth.synthesizeNew()

proc constructSynth*(): Kurumi3Synth = 
    var context = Kurumi3Synth()
    context.modMatrix = [
        0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        ]

    context.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]
    for i in 0..<NB_OPS:
        context.operators[i] = Operator()

    context.operators[3].volAdsr.peak = 1
    context.synthInfos = SynthInfos()
    context.synthesize()
    return context

import strutils
proc generateWaveStr*(synth: Kurumi3Synth, hex: bool = false): string =
    var str = ""
    for i in 0..<synth.synthInfos.waveDims.x:
        if(hex):
            var num = $(synth.outputInt[i]).toHex().strip(true, chars = {'0'})
            if(num == ""): num = "0"
            str &= num & " "
        else:
            str &= $synth.outputInt[i] & " "

    return str & ";"

proc generateSeqStr*(synth: Kurumi3Synth, hex: bool = false): string =
    let macroBackup = synth.synthInfos.macroFrame
    var outStr = ""
    for mac in 0..<synth.synthInfos.macroLen:
        synth.synthInfos.macroFrame = mac
        synth.synthesize()
        outStr &= synth.generateWaveStr(hex) & "\n"
    synth.synthInfos.macroFrame = macroBackup
    synth.synthesize()
    return outStr

