import module
import ../globals
import ../utils/utils
import math

type
    ChebyshevFilter = ref object
        order: int32 = 4
        A: array[32, float64]
        w0: array[32, float64]
        w1: array[32, float64]
        w2: array[32, float64]
        d1: array[32, float64]
        d2: array[32, float64]
        ep: float64
        cutoff, q: float64 = 0.0

    ChebyshevFilterModule* = ref object of SynthModule
        cutoffEnvelope*: Adsr = Adsr(peak: 1.0)
        useCutoffEnvelope*: bool = false
        qEnvelope*: Adsr = Adsr(peak: 0.01)
        useQEnvelope*: bool = false
        filterType*: int32 = 0
        order*: int32 = 4
        note*: int32 = 0
        filter: ChebyshevFilter
        buffer: array[4096 * 8, float64]

    FilterTypes = enum
        LOWPASS,
        HIGHPASS,

proc notetofreq(n: float64): float64 =
    return 440 * pow(2, (n-69)/12)

const LENGTH = 4096.0

proc setChebyshevFilter(filterModule: ChebyshevFilterModule, cutoff: float64, q: float): void =
    filterModule.filter = new ChebyshevFilter
    let sampleRate = notetofreq(filterModule.note.float64) * LENGTH
    # var norm = 0.0
    var K = tan(PI * cutoff / sampleRate)
    var K2 = K * K
    var u = ln((1.0 + sqrt(1.0 + q * q)) / q)
    var su = sinh(u / filterModule.order.float64)
    var cu = cosh(u / filterModule.order.float64)
    var b, c: float64

    case filterModule.filtertype.FilterTypes:
    of LOWPASS:
        for i in 0..<(filterModule.order div 2):
            b = sin(PI * (2.0 * i.float64 + 1.0) / (2.0 * filterModule.order.float64)) * su
            c = cos(PI * (2.0 * i.float64 + 1.0) / (2.0 * filterModule.order.float64)) * cu
            c = b * b + c * c
            var s = K2 * c + 2.0 * K * b + 1.0
            filterModule.filter.A[i] = K2 / (4.0 * s)
            filterModule.filter.d1[i] = 2.0 * (1.0 - K2 * c) / s
            filterModule.filter.d2[i] = -(K2 * c - 2.0 * K * b + 1.0) / s
        filterModule.filter.ep = 2 / sqrt(1 + q * q)

    of HIGHPASS:
        for i in 0..<(filterModule.order div 2):
            b = sin(PI * (2.0 * i.float64 + 1.0) / (2.0 * filterModule.order.float64)) * su
            c = cos(PI * (2.0 * i.float64 + 1.0) / (2.0 * filterModule.order.float64)) * cu
            c = b * b + c * c
            var s = K2 + 2.0 * K * b + c
            filterModule.filter.A[i] = 1.0 / (4.0 * s)
            filterModule.filter.d1[i] = 2.0 * (c - K2) / s
            filterModule.filter.d2[i] = -(K2 - 2.0 * K * b + c) / s
        filterModule.filter.ep = 2 / sqrt(1 + q * q)

    

proc constructChebyshevFilterModule*(): ChebyshevFilterModule =
    var module = new ChebyshevFilterModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    let sampleRate = notetofreq(module.note.float64) * LENGTH
    var filterCutoff = 5 * pow(10, module.cutoffEnvelope.peak * 3)
    filterCutoff = min(sampleRate/2, filterCutoff)
    # module.filter = new BqFilter
    module.setChebyshevFilter(filterCutoff, module.qEnvelope.peak)
    return module

proc processChebyshevFilter*(module: ChebyshevFilterModule, x: float64): float64 =
    var x = x
    case module.filterType.FilterTypes:
    of LOWPASS:
        for i in 0..<(module.order div 2):
            module.filter.w0[i] = module.filter.d1[i] * module.filter.w1[i] + module.filter.d2[i] * module.filter.w2[i] + x
            x = module.filter.A[i]*(module.filter.w0[i] + 2.0 * module.filter.w1[i] + module.filter.w2[i])
            module.filter.w2[i] = module.filter.w1[i]
            module.filter.w1[i] = module.filter.w0[i]
    of HIGHPASS:
        for i in 0..<(module.order div 2):
            module.filter.w0[i] = module.filter.d1[i] * module.filter.w1[i] + module.filter.d2[i] * module.filter.w2[i] + x
            x = module.filter.A[i]*(module.filter.w0[i] - 2.0 * module.filter.w1[i] + module.filter.w2[i])
            module.filter.w2[i] = module.filter.w1[i]
            module.filter.w1[i] = module.filter.w0[i]
    return x * module.filter.ep

method synthesize*(module: ChebyshevFilterModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]

    if(module.update):
        let sampleRate = notetofreq(module.note.float64) * LENGTH
        let mCutoff = if(module.useCutoffEnvelope): module.cutoffEnvelope.doAdsr() else: module.cutoffEnvelope.peak
        let mResonance = if(module.useQEnvelope): module.qEnvelope.doAdsr() else: module.qEnvelope.peak
        var filterCutoff = 5 * pow(10, mCutoff * 3)
        filterCutoff = min(sampleRate/2, filterCutoff)
        module.setChebyshevFilter(filterCutoff, mResonance)
        if(moduleA == nil):
            for i in 0..<module.buffer.len:
                module.buffer[i] = 0
        else:
            # Preheat
            for a in 0..<11:
                for i in 0..<LENGTH.int:
                    let ratio = i.float64 / LENGTH
                    let val = moduleA.synthesize((ratio.float64 * PI * 2), module.inputs[0].pinIndex)
                    discard module.processChebyshevFilter(val)

            for i in 0..<LENGTH.int:
                    let ratio = i.float64 / LENGTH
                    let val = moduleA.synthesize((ratio.float64 * PI * 2), module.inputs[0].pinIndex)
                    module.buffer[i] = module.processChebyshevFilter(val)
        module.update = false

    if(moduleA == nil): return 0.0
    let delta = 1.0 / LENGTH
    return module.buffer[math.floor(moduloFix(x / (2 * PI), 1)/delta).int] 

import ../serializationObject
import flatty

method serialize*(module: ChebyshevFilterModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.CH_FILTER, data: toFlatty(module))