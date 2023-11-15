import module
import ../globals
import ../utils/utils
import ../synthInfos
import mathexpr
import math
import ../synthInfos

type
    WaveShaperModule* = ref object of SynthModule
        formula*: string = "sin(x)"
        a*: Adsr = Adsr(peak: 1.0)
        b*: Adsr = Adsr(peak: 1.0)
        c*: Adsr = Adsr(peak: 1.0)
        d*: Adsr = Adsr(peak: 1.0)
        useAdsrA*: bool
        useAdsrB*: bool
        useAdsrC*: bool
        useAdsrD*: bool
proc constructWaveShaperModule*(): WaveShaperModule =
    var module = new WaveShaperModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        ]
    return module

proc avg(args: seq[float]): float =
    var sum = 0.0
    for i in args:
        sum += i
    return sum / args.len.float

proc myClip(args: seq[float]): float =
    return clamp(args[1], args[0], args[2])

proc myClamp(args: seq[float]): float =
    if(args[1] <= args[2] and args[1] >= args[0]): return args[1]
    # if(moduloFix(args[1], args[2]) == 0 and args[1] != 0): return args[2]
    return moduloFix(args[1] - args[0], args[2] - args[0]) + args[0]

proc mySign(args: seq[float]): float =
    return if(signbit(args[0])): -1 else: 1

proc quant(args: seq[float]): float =
    if(args[1] == 0): return args[0]
    return floor(args[0]/args[1] + 0.5)/(1/args[1])

proc quantToBits(args: seq[float]): float =
    let powOf2 = pow(2.0, args[1])
    if(powOf2 == 0): return 0
    return floor(args[0] * powOf2 * 0.5 + 0.5) / (powOf2 * 0.5)

proc logn(args: seq[float]): float =
    let output = log(args[0], args[1])
    return if(output.isNaN): 0 else: output

proc chebyshev(x, n: float): float =
    if n == 0:
        return 1
    if n == 1:
        return x
    return 2 * x * chebyshev(n - 1, x) - chebyshev(n - 2, x)

proc cheby(args: seq[float]): float =
    let n = args[1].int
    let x = args[0]
    if n == 0: return 1
    if n == 1: return x
    var t_n_m_2 = 1.0
    var t_n_m_1 = x
    var t_n = 0.0

    for i in 2..(n):
        t_n = 2 * x * t_n_m_1 - t_n_m_2
        t_n_m_2 = t_n_m_1
        t_n_m_1 = t_n

    return t_n

proc chebyRec(args: seq[float]): float =
    return chebyshev(args[0], args[1])

proc ipart(args: seq[float]): float =
    return args[0].floor()

proc fpart(args: seq[float]): float =
    return args[0] - args[0].floor()

proc myIf(args: seq[float]): float =
    if args[0] != 0: return args[1] else: return args[2]

proc select(args: seq[float]): float =
    let c = args[0]
    let n = args[1]
    let z = args[2]
    let p = args[3]

    if c < 0.0: return n
    if c == 0.0: return z
    if c > 0.0: return p

proc equal(args: seq[float]): float =
    return (args[0] == args[1]).float

proc below(args: seq[float]): float =
    return (args[0] < args[1]).float

proc above(args: seq[float]): float =
    return (args[0] > args[1]).float

proc belowEq(args: seq[float]): float =
    return (args[0] <= args[1]).float

proc aboveEq(args: seq[float]): float =
    return (args[0] >= args[1]).float

proc myAnd(args: seq[float]): float =
    return (args[0] != 0.0 and args[1] != 0.0).float

proc myOr(args: seq[float]): float =
    return (args[0] != 0.0 or args[1] != 0.0).float

proc myXor(args: seq[float]): float =
    return (args[0] != 0.0 xor args[1] != 0.0).float

proc myNot(args: seq[float]): float =
    return (args[0] == 0).float

proc myDeg(args: seq[float]): float =
    return radToDeg(args[0])

proc myRad(args: seq[float]): float =
    return degToRad(args[0])



proc addVariables(e: Evaluator, module: WaveShaperModule, x: float64, synthInfos: SynthInfos): void =
    e.addVars(
            {
                "a": module.a.doAdsr(synthInfos.macroFrame),
                "b": module.b.doAdsr(synthInfos.macroFrame),
                "c": module.c.doAdsr(synthInfos.macroFrame),
                "d": module.d.doAdsr(synthInfos.macroFrame),
                
                "x": x,

                # "env": module.envelope.doAdsr(synthInfos.macroFrame),
                # "est": module.envelope.start.float64,
                # "ea1": module.envelope.attack.float64,
                # "ep1": module.envelope.peak.float64,
                # "ed1": module.envelope.decay.float64,
                # "es1": module.envelope.sustain.float64,
                # "ea2": module.envelope.attack2.float64,
                # "ep2": module.envelope.peak2.float64,
                # "ed2": module.envelope.decay2.float64,
                # "es2": module.envelope.sustain2.float64,
                
                "flan": 495.0
            }
        )

    

    
    e.addFunc("clip", myClip, 3)
    e.addFunc("clamp", myClamp, 3)
    e.addFunc("avg", avg)
    e.addFunc("sign", mySign, 1)
    e.addFunc("quant", quant, 2)
    e.addFunc("quantToBits", quantToBits, 2)
    e.addFunc("logn", logn, 2)
    e.addFunc("cheby", cheby, 2)
    e.addFunc("ipart", ipart, 1)
    e.addFunc("fpart", fpart, 1)

    e.addFunc("if", myIf, 3)
    e.addFunc("select", select, 4)
    e.addFunc("equal", equal, 2)
    e.addFunc("below", below, 2)
    e.addFunc("beloweq", belowEq, 2)
    e.addFunc("above", above, 2)
    e.addFunc("aboveeq", aboveEq, 2)

    e.addFunc("and", myAnd, 2)
    e.addFunc("or", myOr, 2)
    e.addFunc("xor", myXor, 2)
    e.addFunc("not", myNot, 1)

    e.addFunc("deg", myDeg, 1)
    e.addFunc("rad", myRad, 1)
    

proc computeEval*(module: WaveShaperModule, x: float64, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let e = newEvaluator()

    e.addVariables(module, x, synthInfos)

    proc synth(args: seq[float]): float =
        if(args[0].int > 1 or args[0].int < 0): return 0
        if(module.inputs[args[0].int].moduleIndex < 0): return 0
        let moduleE = moduleList[module.inputs[args[0].int].moduleIndex]
        if(moduleE == nil): return 0 else: return moduleE.synthesize(moduloFix(args[1], 2 * PI), module.inputs[args[0].int].pinIndex, moduleList, synthInfos)
    
    e.addFunc("synth", synth, 2)
    var output = 0.0
    try:
        output = e.eval(module.formula)    
    except ValueError:
        return output
    return if(output.isNaN): 0 else: output

    

method synthesize(module: WaveShaperModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =

    if(module.inputs[0].moduleIndex < 0):
        return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil):
        return 0
    let x1 = moduleA.synthesize(x, pin, moduleList, synthInfos).float64
    let e = newEvaluator()

    e.addVariables(module, x1, synthInfos)

    proc synth(args: seq[float]): float =
        if(args[0].int > 1 or args[0].int < 0): return 0
        if(module.inputs[args[0].int].moduleIndex < 0): return 0
        let moduleE = moduleList[module.inputs[args[0].int].moduleIndex]
        if(moduleE == nil): return 0 else: return moduleE.synthesize(moduloFix(args[1], 2 * PI), module.inputs[args[0].int].pinIndex, moduleList, synthInfos)
    
    e.addFunc("synth", synth, 2)
    # proc synth(args: seq[float]): float =
    #     if(args[0].int > 3 or args[0].int < 0): return 0
    #     if(module.inputs[args[0].int].moduleIndex < 0): return 0
    #     let moduleE = moduleList[module.inputs[args[0].int].moduleIndex]
    #     if(moduleE == nil): return 0 else: return moduleE.synthesize(args[1], pin, moduleList, synthInfos)

    # e.addFunc("synth", synth, 2)
    

    var output = 0.0
    try:
        output = e.eval(module.formula)    
    except ValueError:
        return output
    output = if(isNaN(output)): 0.0 else: output
    return output
        

import ../serializationObject
import flatty

method serialize*(module: WaveShaperModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.WAVE_SHAPER, data: toFlatty(module))