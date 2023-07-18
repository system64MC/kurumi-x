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
    return log(args[0], args[1])

proc addVariables(e: Evaluator, module: WaveShaperModule, x: float64, synthInfos: SynthInfos): void =
    e.addVars(
            {
                "a": if(module.useAdsrA): module.a.doAdsr(synthInfos.macroFrame) else: module.a.peak,
                "b": if(module.useAdsrB): module.b.doAdsr(synthInfos.macroFrame) else: module.b.peak,
                "c": if(module.useAdsrC): module.c.doAdsr(synthInfos.macroFrame) else: module.c.peak,
                "d": if(module.useAdsrD): module.d.doAdsr(synthInfos.macroFrame) else: module.d.peak,
                
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

    

    
    e.addFunc("clamp", myClip, 3)
    e.addFunc("avg", avg)
    e.addFunc("sign", mySign, 1)
    e.addFunc("quant", quant, 2)
    e.addFunc("quantToBits", quantToBits, 2)
    e.addFunc("logn", logn, 2)
    

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