import module
import ../utils/utils
import ../synthInfos
import ../globals
import math
import std/strutils

const squareTable = [1.0, -1.0]


type
    SineOscillatorModule* = ref object of SynthModule
        phase*: float32
        mult*: int32 = 1
        detune*: int32 = 0

    SquareOscillatorModule* = ref object of SineOscillatorModule
        dutyEnvelope*: Adsr = Adsr(peak: 0.5)
        useAdsr*: bool = false

    TriangleOscillatorModule* = ref object of SineOscillatorModule

    SawOscillatorModule* = ref object of SineOscillatorModule

    WavetableOscillatorModule* = ref object of SineOscillatorModule
        wavetable*: seq[uint8] = @[16, 25, 30, 31, 30, 29, 26, 25, 25, 28, 31, 28, 18, 11, 10, 13, 17, 20, 22, 20, 15, 6, 0, 2, 6, 5, 3, 1, 0, 0, 1, 4]
        waveStr*: string = "16 25 30 31 30 29 26 25 25 28 31 28 18 11 10 13 17 20 22 20 15 6 0 2 6 5 3 1 0 0 1 4"
        interpolation*: int32 = 0
        minSample*: uint8 = 0
        maxSample*: uint8 = 31

    InterpolationTypes = enum
        NEAREST,
        LINEAR,
        CUBIC,


method getMult(module: SineOscillatorModule): float64 {.base.} =
    if(module.mult == 0): return 0.5 else: return module.mult.float64

method getPhase(module: SineOscillatorModule, mac: int32, macLen: int32): float64 {.base.} =
    var mac = mac.float64
    var macLen = macLen.float64

    # Anti-divide by 0
    if(macLen < 2): macLen = 2
    return mac.float64 / (macLen - 1) * module.detune.float64

proc constructSineOscillatorModule*(): SineOscillatorModule =
    var module = new SineOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: SineOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let myMult = module.getMult()
    return sin((x * myMult) + (module.phase * 2 * PI + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen) * PI * 2))



proc constructSquareOscillatorModule*(): SquareOscillatorModule =
    var module = new SquareOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: SquareOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let myMult = module.getMult()
    let val = (x * myMult / (PI * 2)) + (module.phase + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen))
    let duty = if(module.useAdsr): module.dutyEnvelope.doAdsr(synthInfos.macroFrame) else: module.dutyEnvelope.peak
    return if(moduloFix(val, 1) < (duty)): 1 else: -1


proc constructTriangleOscillatorModule*(): TriangleOscillatorModule =
    var module = new TriangleOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: TriangleOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let myMult = module.getMult()
    return arcsin(sin((x * myMult) + (module.phase * 2 * PI + (module.getPhase(synthInfos.macroFrame, synthInfos.macroLen) * PI * 2)))) / (PI * 0.5)


proc constructSawOscillatorModule*(): SawOscillatorModule =
    var module = new SawOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: SawOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let myMult = module.getMult()
    return arctan(tan((x / 2)*myMult+module.phase*math.Pi + (module.getPhase(synthInfos.macroFrame, synthInfos.macroLen) * PI))) / (Pi * 0.5)


proc constructWavetableOscillatorModule*(): WavetableOscillatorModule =
    var module = new WavetableOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method refreshWaveform*(module: WavetableOscillatorModule) {.base.} =
    module.wavetable = @[]
    module.maxSample = 0
    module.minSample = 0
    for num in module.waveStr.split:
        try:
            let smp = parseUInt(num).uint8
            module.wavetable.add(smp)
            if smp > module.maxSample: module.maxSample = smp
            if smp < module.minSample: module.minSample = smp        
        except ValueError:
            continue
    if module.wavetable.len == 0:
        module.wavetable = @[0]
        module.maxSample = 0
        module.minSample = 0

method interpolate(module: WavetableOscillatorModule, x: float64): float64 {.base.} =
    let x2 = x * module.wavetable.len.float64
    let len = module.wavetable.len.float64
    let idx = floor(x2)
    case module.interpolation.InterpolationTypes:
    of NEAREST:
        return (module.wavetable[moduloFix(idx, len).int].float64 / (module.maxSample.float64 / 2)) - 1.0
    of LINEAR:
        let mu = x2 - idx
        let s0 = (module.wavetable[moduloFix(idx, len).int].float64 / (module.maxSample.float64 / 2)) - 1.0
        let s1 = (module.wavetable[moduloFix(idx + 1, len).int].float64 / (module.maxSample.float64 / 2)) - 1.0
        return s0 + mu*s1 - (mu * s0)
    of CUBIC:
        return 0
    

method synthesize(module: WavetableOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let myMult = module.getMult()
    let x2 = ((x * myMult) + (module.phase * 2 * PI + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen) * PI * 2)) / (2 * PI)
    return module.interpolate(x2)

import ../serializationObject
import flatty

method serialize*(module: SineOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.SINE_OSC, data: toFlatty(module))

method serialize*(module: TriangleOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.TRI_OSC, data: toFlatty(module))

method serialize*(module: SawOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.SAW_OSC, data: toFlatty(module))

method serialize*(module: SquareOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.PULSE_OSC, data: toFlatty(module))

method serialize*(module: WavetableOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.WAVE_OSC, data: toFlatty(module))