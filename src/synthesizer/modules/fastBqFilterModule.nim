import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    BqFilter = ref object
        a0, a1, a2, b1, b2: float64 = 0.0 #factors
        cutoff, q, peakGain: float64 = 0.0
        z1, z2: float64 = 0.0 #poles

    FastBqFilterModule* = ref object of SynthModule
        cutoffEnvelope*: Adsr = Adsr(peak: 1.0)
        useCutoffEnvelope*: bool = false
        qEnvelope*: Adsr = Adsr(peak: 0.01)
        useQEnvelope*: bool = false
        filterType*: int32 = 0
        note*: int32 = 0
        filter: BqFilter
        buffer: array[4096 * 8, float64]
        normalize*: bool = false
        min: float64 = 0
        max: float64 = 0

    FilterTypes = enum
        LOWPASS,
        HIGHPASS,
        BANDPASS,
        BANDSTOP,
        ALLPASS,

proc notetofreq(n: float64): float64 =
    return 440 * pow(2, (n-69)/12)

const LENGTH = 4096.0

proc setBqFilter(filterModule: FastBqFilterModule, cutoff: float64, q: float, synthInfos: SynthInfos): void =
    filterModule.filter = new BqFilter
    let sampleRate = notetofreq(filterModule.note.float64) * (synthInfos.waveDims.x * synthInfos.oversample).float64
    var norm = 0.0
    var K = tan(PI * cutoff / sampleRate)
    case filterModule.filtertype.FilterTypes:
    of LOWPASS:
        if(q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(q) + K*K)
        filterModule.filter.a0 = K * K * norm
        filterModule.filter.a1 = 2 * filterModule.filter.a0
        filterModule.filter.a2 = filterModule.filter.a0
        filterModule.filter.b1 = 2 * (K * K - 1) * norm
        if(q == 0):
            filterModule.filter.b2 = 0
        else:
            filterModule.filter.b2 = (1 - K/float64(q) + K*K) * norm
    of HIGHPASS:
        if(q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(q) + K*K)
        filterModule.filter.a0 = norm
        filterModule.filter.a1 = -2 * filterModule.filter.a0
        filterModule.filter.a2 = filterModule.filter.a0
        filterModule.filter.b1 = 2 * (K*K - 1) * norm
        if(q == 0):
            filterModule.filter.b2 = 0
        else:
            filterModule.filter.b2 = (1 - K/float64(q) + K*K) * norm

    of BANDPASS:
        if(q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(q) + K*K)
        filterModule.filter.a0 = K / q * norm
        filterModule.filter.a1 = 0
        filterModule.filter.a2 = -filterModule.filter.a0
        filterModule.filter.b1 = 2 * (K*K - 1) * norm
        if(q == 0):
            filterModule.filter.b2 = 0
        else:
            filterModule.filter.b2 = (1 - K/float64(q) + K*K) * norm

    of BANDSTOP:
        if(q == 0):
            norm = 0
        else:
            norm = 1 / (1 + K/float64(q) + K*K)
        filterModule.filter.a0 = (1 + K*K) * norm
        filterModule.filter.a1 = 2 * (K*K - 1) * norm
        filterModule.filter.a2 = filterModule.filter.a0
        filterModule.filter.b1 = filterModule.filter.a1
        if(q == 0):
            filterModule.filter.b2 = 0
        else:
            filterModule.filter.b2 = (1 - K/float64(q) + K*K) * norm

    of ALLPASS:
        let aa = (K - 1.0) / (K + 1.0)
        let bb = -cos(PI * cutoff / sampleRate)
        filterModule.filter.a0 = -aa
        filterModule.filter.a1 = bb * (1.0 - aa)
        filterModule.filter.a2 = 1.0
        filterModule.filter.b1 = filterModule.filter.a1
        filterModule.filter.b2 = filterModule.filter.a0

    

proc constructFastBqFilterModule*(synthInfos: SynthInfos): FastBqFilterModule =
    var module = new FastBqFilterModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    let sampleRate = notetofreq(module.note.float64) * (synthInfos.waveDims.x * synthInfos.oversample).float64
    var filterCutoff = 5 * pow(10, module.cutoffEnvelope.peak * 3)
    filterCutoff = min(sampleRate/2, filterCutoff)
    # module.filter = new BqFilter
    module.setBqFilter(filterCutoff, module.qEnvelope.peak, synthInfos)
    return module

proc processBqFilter*(module: FastBqFilterModule, x: float64): float64 =
    let output = x * module.filter.a0 + module.filter.z1
    module.filter.z1 = x * module.filter.a1 + module.filter.z2 - module.filter.b1 * output
    module.filter.z2 = x * module.filter.a2 - module.filter.b2 * output
    return output

method synthesize*(module: FastBqFilterModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]

    if(module.update):
        let sampleRate = notetofreq(module.note.float64) * (synthInfos.waveDims.x * synthInfos.oversample).float64
        let mCutoff = if(module.useCutoffEnvelope): module.cutoffEnvelope.doAdsr(synthInfos.macroFrame) else: module.cutoffEnvelope.peak
        let mResonance = if(module.useQEnvelope): module.qEnvelope.doAdsr(synthInfos.macroFrame) else: module.qEnvelope.peak
        var filterCutoff = 5 * pow(10, mCutoff * 3)
        filterCutoff = min(sampleRate/2, filterCutoff)
        module.setBqFilter(filterCutoff, mResonance, synthInfos)
        module.min = 0
        module.max = 0
        if(moduleA == nil):
            for i in 0..<module.buffer.len:
                module.buffer[i] = 0
        else:
            # Preheat
            for a in 0..<11:
                for i in 0..<(synthInfos.waveDims.x * synthInfos.oversample).int:
                    let ratio = i.float64 / (synthInfos.waveDims.x * synthInfos.oversample).float64
                    let val = moduleA.synthesize((ratio.float64 * PI * 2), module.inputs[0].pinIndex, moduleList, synthInfos)
                    discard module.processBqFilter(val)

            for i in 0..<(synthInfos.waveDims.x * synthInfos.oversample).int:
                    let ratio = i.float64 / (synthInfos.waveDims.x * synthInfos.oversample).float64
                    let val = moduleA.synthesize((ratio.float64 * PI * 2), module.inputs[0].pinIndex, moduleList, synthInfos)
                    let res = module.processBqFilter(val)
                    module.buffer[i] = res
                    module.max = max(module.max, res)
                    module.min = min(module.min, res)

        module.update = false

    if(moduleA == nil): return 0.0
    let delta = 1.0 / (synthInfos.waveDims.x * synthInfos.oversample).float64
    let output = module.buffer[math.floor(moduloFix(x / (2 * PI), 1)/delta).int] 
    if(module.normalize):
        let norm = max(abs(module.max), abs(module.min))
        if norm == 0: return output
        return output * (1 / norm)

    return output

import ../serializationObject
import flatty

method serialize*(module: FastBqFilterModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.FAST_BQ_FILTER, data: toFlatty(module))