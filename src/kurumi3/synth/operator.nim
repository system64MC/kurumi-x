# import Adsr
import ../../common/synthInfos
import ../../common/globals
import ../../common/utils
import random
import strutils

type
    Operator* = ref object
        modMode*: int32
        feedback*: float32
        mult*: int32 = 1
        phase*: float32
        distAdsr*: Adsr = Adsr(mac: @[255], macString: "255", peak: 1.0)
        distMode*: int32 = 0
        volAdsr*: Adsr
        detune*: int32
        morphEnvelope*: Adsr = Adsr(attack: 64, peak: 0)
        pwmEnv*: Adsr = Adsr(peak: 0.5, mac: @[128], macString: "128")
        waveform*: int32
        reverseWaveform*: bool
        interpolation*: int32
        wavetable*: seq[uint8] = @[16, 25, 30, 31, 30, 29, 26, 25, 25, 28, 31, 28, 18, 11, 10, 13, 17, 20, 22, 20, 15, 6, 0, 2, 6, 5, 3, 1, 0, 0, 1, 4]
        waveStr*: string = "16 25 30 31 30 29 26 25 25 28 31 28 18 11 10 13 17 20 22 20 15 6 0 2 6 5 3 1 0 0 1 4"
        waveMin*: uint8 = 0
        waveMax*: uint8 = 31
        morphWave*: seq[uint8] = @[16, 20, 15, 11, 11, 24, 30, 31, 28, 20, 10, 2, 0, 3, 5, 0, 16, 31, 26, 28, 31, 29, 21, 11, 3, 0, 1, 7, 20, 20, 16, 11]
        morphStr*: string = "16 20 15 11 11 24 30 31 28 20 10 2 0 3 5 0 16 31 26 28 31 29 21 11 3 0 1 7 20 20 16 11"
        morphMin*: uint8 = 0
        morphMax*: uint8 = 31
        phaseEnv*: Adsr = Adsr(mac: @[0], macString: "0")
        expEnv*: Adsr = Adsr(peak: 1, mac: @[255], macString: "255")
        # phaseStr*: string = "0"
        prev*: float64
        curr*: float64

    OperatorSerialize* = object
        modMode*: int32
        feedback*: float32
        mult*: int32 = 1
        phase*: float32
        distAdsr*: AdsrSerialize
        distMode*: int32
        volAdsr*: AdsrSerialize
        detune*: int32
        morphEnvelope*: AdsrSerialize
        pwmEnv*: AdsrSerialize
        waveform*: int32
        reverseWaveform*: bool
        interpolation*: int32
        wavetable*: seq[uint8]
        morphWave*: seq[uint8]
        phaseEnv*: AdsrSerialize
        expEnv*: AdsrSerialize

    VolEnvMode* = enum
        NONE,
        ADSR,
        CUSTOM

proc serializeOperator*(op: Operator): OperatorSerialize =
    return OperatorSerialize(
        modMode: op.modMode,
        feedback: op.feedback,
        mult: op.mult,
        phase: op.phase,
        distAdsr: op.distAdsr.serializeAdsr(),
        distMode: op.distMode,
        volAdsr: op.volAdsr.serializeAdsr(),
        detune: op.detune,
        morphEnvelope: op.morphEnvelope.serializeAdsr(),
        pwmEnv: op.pwmEnv.serializeAdsr(),
        waveform: op.waveform,
        reverseWaveform: op.reverseWaveform,
        interpolation: op.interpolation,
        wavetable: op.wavetable,
        morphWave: op.morphWave,
        phaseEnv: op.phaseEnv.serializeAdsr(),
        expEnv: op.expEnv.serializeAdsr()
    )

import math

func `%`*(a, b: float64): float64 = 
    let tmp = (a mod b) + b
    return tmp mod b

func `%`*(a, b: int): int = 
    let tmp = (a mod b) + b
    return tmp mod b



type
    Destination* = enum
        WAVETABLE,
        VOLUME,
        DUTY,
        MORPH,

proc refreshWavetable(op: Operator) =
    op.wavetable = @[]
    op.waveMin = 0
    op.waveMax = 0
    for num in op.waveStr.split:
        try:
            let smp = parseUInt(num).uint8
            op.wavetable.add(smp)
            if smp > op.waveMax: op.waveMax = smp
            if smp < op.waveMin: op.waveMin = smp        
        except ValueError:
            continue
    if op.wavetable.len == 0:
        op.wavetable = @[0]
        op.waveMin = 0
        op.waveMax = 0

proc refreshMorph(op: Operator) =
    op.morphWave = @[]
    op.morphMin = 0
    op.morphMax = 0
    for num in op.morphStr.split:
        try:
            let smp = parseUInt(num).uint8
            op.morphWave.add(smp)
            if smp > op.morphMax: op.morphMax = smp
            if smp < op.morphMin: op.morphMin = smp        
        except ValueError:
            continue
    if op.morphWave.len == 0:
        op.morphWave = @[0]
        op.morphMin = 0
        op.morphMax = 0

proc refreshVolumeEnv(op: Operator) =
    op.volAdsr.mac = @[]
    for num in op.volAdsr.macString.split:
        try:
            let smp = parseUInt(num).uint8
            op.volAdsr.mac.add(smp)
        except ValueError:
            continue
    if op.volAdsr.mac.len == 0:
        op.volAdsr.mac = @[0]

proc refreshDuty(op: Operator) =
    op.pwmEnv.mac = @[]
    for num in op.pwmEnv.macString.split:
        try:
            let smp = parseUInt(num).uint8
            op.pwmEnv.mac.add(smp)
        except ValueError:
            continue
    if op.pwmEnv.mac.len == 0:
        op.volAdsr.mac = @[128]

proc refreshWaveform*(op: Operator, destination: Destination = WAVETABLE) =
    case destination:
    of WAVETABLE: op.refreshWavetable()
    of VOLUME: op.refreshVolumeEnv()
    of DUTY: op.refreshDuty()
    of MORPH: op.refreshMorph()

func getMult(op: Operator): float64 =
    if(op.mult != 0): return op.mult.float64
    return 0.5

func getPhase(op: Operator, infos: SynthInfos): float64 =
    if(op.phaseEnv.mode == 0):
        let macLen = max(infos.macroLen, 2)
        return (infos.macroFrame.float64 / float64(macLen-1)) * float64(op.detune)
    return op.phaseEnv.doAdsr(infos.macroFrame) * op.detune.float64

func getDutyCycle(op: Operator, infos: SynthInfos): float64 =
    return op.pwmEnv.doAdsr(infos.macroFrame)
    # return op.pwmEnv.peak

proc lsfrShift(infos: SynthInfos) =
    let lsfr = infos.lsfr
    infos.lsfr = (lsfr shl 1) or (((lsfr shr 13) xor (lsfr shr 14)) and 1)

type
    InterpolationTypes = enum
        NEAREST,
        LINEAR,
        COSINE,
        CUBIC,
proc interpolate(op: Operator, x: float64, wt: seq[byte], min, max: byte): float64 =
    let x2 = x
    let len = wt.len.float64
    let idx = floor(x2)
    # echo idx.int
    case op.interpolation.InterpolationTypes:
    of NEAREST:
        let s = (wt[idx.int % len.int].float64 / (max.float64 / 2)) - 1.0
        # echo len
        return s 
    of LINEAR:
        let mu = x2 - idx
        let s0 = (wt[idx.int % len.int].float64 / (max.float64 / 2)) - 1.0
        let s1 = (wt[(idx.int + 1) % len.int].float64 / (max.float64 / 2)) - 1.0
        return s0 + mu*s1 - (mu * s0)
    of COSINE:
        let mu = x2 - idx
        let mucos = (1 - cos(mu * PI) / 2)
        let s0 = (wt[idx.int % len.int].float64 / (max.float64 / 2)) - 1.0
        let s1 = (wt[(idx.int + 1) % len.int].float64 / (max.float64 / 2)) - 1.0
        return s0 + mucos * s1 - (mucos * s0)
    of CUBIC:
        let
            s0 = (wt[(idx.int - 1) % len.int].float64 / (max.float64 / 2)) - 1
            s1 = (wt[(idx.int + 0) % len.int].float64 / (max.float64 / 2)) - 1
            s2 = (wt[(idx.int + 1) % len.int].float64 / (max.float64 / 2)) - 1
            s3 = (wt[(idx.int + 2) % len.int].float64 / (max.float64 / 2)) - 1

            mu = x - idx.float64
            mu2 = mu * mu
            
            a0 = -0.5*s0 + 1.5*s1 - 1.5*s2 + 0.5*s3
            a1 = s0 - 2.5*s1 + 2*s2 - 0.5*s3
            a2 = -0.5*s0 + 0.5*s2
            a3 = s1

        return (a0*mu*mu2 + a1*mu2 + a2*mu + a3)

func lerp(x, y, a: float64): float64 =
    return x*(1-a) + y*a
# proc getWTSample(op: Operator, x: float64, infos: SynthInfos): float64 =
#     let a = op.interpolate(x * op.wavetable.len.float64 * op.getMult() + (op.phase.float64 * op.wavetable.len.float64 + op.getPhase(infos) * op.wavetable.len.float64), op.wavetable, op.waveMin, op.waveMax)
#     let b = op.interpolate(x * op.morphWave.len.float64 * op.getMult() + (op.phase.float64 * op.morphWave.len.float64 + op.getPhase(infos) * op.morphWave.len.float64), op.morphWave, op.morphMin, op.morphMax)
#     let c = op.morphEnvelope.doAdsr(infos.macroFrame)
#     return lerp(a, b, c)

proc getWTSample(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.interpolate((x / (PI * 2)) * op.wavetable.len.float64, op.wavetable, op.waveMin, op.waveMax)
    let b = op.interpolate((x / (PI * 2)) * op.morphWave.len.float64, op.morphWave, op.morphMin, op.morphMax)
    let c = op.morphEnvelope.doAdsr(infos.macroFrame)
    return lerp(a, b, c)

func getFB*(op: Operator): float64 =
    return float64(op.feedback) * (float64(op.prev) / float64(6*op.getMult()))

# Waveforms

    # Sines
# proc sine(op: Operator, x: float64, infos: SynthInfos): float64 =
#     return sin((x * op.getMult() * 2 * PI) + ((op.phase.float64) * 2 * PI + (op.getPhase(infos) * PI * 2)))

proc sine(op: Operator, x: float64, infos: SynthInfos): float64 =
    return sin(x)
    # (x * op.getMult() * 2 * math.Pi) + (float64(op.Phase)*2*math.Pi + (op.getPhase() * math.Pi * 2))

proc rectSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.sine(x, infos)
    return if(a > 0): a else: 0

proc absSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    return abs(op.sine(x, infos))

proc quarterSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    if(x mod PI * 0.5 <= PI * 0.25):
    # if (x * op.getMult() + op.phase.float64 + op.getPhase(infos)) mod 0.5 <= 0.25:
        return op.absSine(x, infos)
    return 0

proc squishedSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    if(op.sine(x, infos) > 0):
        return sin(x * 2)
    return 0

proc squishedRectSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedSine(x, infos)
    return if(a > 0): a else: 0

proc squishedAbsSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    return abs(op.squishedSine(x, infos))

    # Squares
proc square(op: Operator, x: float64, infos: SynthInfos): float64 =
    let width = op.getDutyCycle(infos)
    let a = (x) % (PI * 2)    
    if a >= (PI * width * 2): return -1
    return 1

proc rectSquare(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.square(x, infos)
    if(a < 0): return 0
    return a

    # Saws
proc saw(op: Operator, x: float64, infos: SynthInfos): float64 =
    return arctan(tan(x / 2)) / (PI * 0.5)

proc rectSaw(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.saw(x, infos)
    if(a < 0): return 0
    return a

proc absSaw(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.saw(x, infos)
    if(a < 0): return a + 1
    return a

    # Cubed Saws
proc cubSaw(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.saw(x, infos)
    return a * a * a

proc rectCubSaw(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.rectSaw(x, infos)
    return a * a * a

proc rectAbsSaw(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.absSaw(x, infos)
    return a * a * a

    # Cubed sines
proc cubedSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.sine(x, infos)
    return a * a * a

proc cubedRectSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.rectSine(x, infos)
    return a * a * a

proc cubedAbsSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.absSine(x, infos)
    return a * a * a

proc cubedQuarterSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.quarterSine(x, infos)
    return a * a * a

proc cubedSquishedSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedSine(x, infos)
    return a * a * a

proc cubedSquishedRectSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedRectSine(x, infos)
    return a * a * a

proc cubedSquishedAbsSine(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedAbsSine(x, infos)
    return a * a * a


    # Triangles
proc triangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    return arcsin(op.sine(x, infos)) / (PI * 0.5)

proc rectTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.triangle(x, infos)
    if(a < 0): return 0
    return a

proc absTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    return abs(op.triangle(x, infos))

proc quarterTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    if (x) mod PI * 0.5 <= PI * 0.25:
        return op.absTriangle(x, infos)
    return 0

proc squishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    if(op.sine(x, infos) > 0):
        return arcsin(sin((x * op.getMult() * 4 * PI) + (op.phase.float64 * PI * 4 + (op.getPhase(infos) * PI * 4)))) / (PI / 2)
    return 0

proc rectSquishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedTriangle(x, infos)
    if(a < 0): return 0
    return a

proc absSquishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    return abs(op.squishedTriangle(x, infos))

    # Cubed Triangles
proc cubedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.triangle(x, infos)
    return a * a * a

proc cubedRectTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.rectTriangle(x, infos)
    return a * a * a

proc cubedAbsTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.absTriangle(x, infos)
    return a * a * a

proc cubedQuarterTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.quarterTriangle(x, infos)
    return a * a * a

proc cubedSquishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.squishedTriangle(x, infos)
    return a * a * a

proc cubedRectSquishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.rectSquishedTriangle(x, infos)
    return a * a * a

proc cubedAbsSquishedTriangle(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.absSquishedTriangle(x, infos)
    return a * a * a

    # Noises
proc noise1bitLsfr(op: Operator, x: float64, infos: SynthInfos): float64 =
    infos.lsfrShift()
    return (infos.lsfr and 1).float64 * 2 - 1

proc noise8bitLsfr(op: Operator, x: float64, infos: SynthInfos): float64 =
    infos.lsfrShift()
    return (infos.lsfr and 255).float64 / 127 - 1

proc noiseRandom(op: Operator, x: float64, infos: SynthInfos): float64 =
    return rand(1.0) * 2 - 1 

proc custom(op: Operator, x: float64, infos: SynthInfos): float64 =
    return op.getWTSample(x, infos)

proc rectCustom(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.custom(x, infos)
    if(a < 0): return 0
    return a

proc absCustom(op: Operator, x: float64, infos: SynthInfos): float64 =
    return abs(op.custom(x, infos))

proc cubedCustom(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.custom(x, infos)
    return a * a * a

proc cubedRectCustom(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.rectCustom(x, infos)
    return a * a * a

proc cubedAbsCustom(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.absCustom(x, infos)
    return a * a * a

const waveFuncs* = [
    sine,
    rectSine,
    absSine,
    quarterSine,
    squishedSine,
    squishedRectSine,
    squishedAbsSine,

    square,
    rectSquare,

    saw,
    rectSaw,
    absSaw,

    cubSaw,
    rectCubSaw,
    rectAbsSaw,

    cubedSine,
    cubedRectSine,
    cubedAbsSine,
    cubedQuarterSine,
    cubedSquishedSine,
    cubedSquishedRectSine,
    cubedSquishedAbsSine,

    triangle,
    rectTriangle,
    absTriangle,
    quarterTriangle,
    squishedTriangle,
    rectSquishedTriangle,
    absSquishedTriangle,

    cubedTriangle,
    cubedRectTriangle,
    cubedAbsTriangle,
    cubedQuarterTriangle,
    cubedSquishedTriangle,
    cubedRectSquishedTriangle,
    cubedAbsSquishedTriangle,

    noise1bitLsfr,
    noise8bitLsfr,
    noiseRandom,

    custom,
    rectCustom,
    absCustom,

    cubedCustom,
    cubedRectCustom,
    cubedAbsCustom,
]
proc linearInterpolation(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))  
proc oscillate*(op: Operator, x: float64, infos: SynthInfos): float64 =
    let a = op.distAdsr.doAdsr(infos.macroFrame)
    let e = op.expEnv.doAdsr(infos.macroFrame)
    let mode = op.distMode
    var myX = (x * op.getMult() * 2 * PI) + ((op.phase.float64) * 2 * PI + (op.getPhase(infos) * PI * 2))
    myX = myX % (2 * PI)
    if(mode < 2):
        if(a == 0): return 0
        let ratio = 1.0 / a
        let myMod = (myX * ratio) % (2 * PI)
        if((myX >= 2 * PI * a) and mode != 1): return 0
        let r = waveFuncs[op.waveform](op, myMod, infos)
        return pow(abs(r), e).copySign(r)
    else:
        if(myX < 2 * PI * a):
            let r = waveFuncs[op.waveform](op, linearInterpolation(0, 0, a, 0.5, myX / (2 * PI)) * 2 * PI, infos)
            return pow(abs(r), e).copySign(r)
        let r = waveFuncs[op.waveform](op, linearInterpolation(a, 0.5, 1.0, 1.0, myX / (2 * PI)) * 2 * PI, infos)
        return pow(abs(r), e).copySign(r)

# let waveforms = [
#     "Sine".cstring,
#     "Rect. Sine",
#     "Abs. Sine",
#     "Quarter Sine",
#     "Squished Sine",
#     "Squished Rect. Sine",
#     "Squished Abs. Sine",

# ]