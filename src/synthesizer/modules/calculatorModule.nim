import module
import ../globals
import ../utils/utils
import ../synthInfos
import mathexpr
import math
import ../synthInfos

type
    CalculatorModule* = ref object of SynthModule
        formula*: string = "sin(x)"
        prev*: float64 = 0
        envelope*: Adsr = Adsr(peak: 1.0)

proc constructCalculatorModule*(): CalculatorModule =
    var module = new CalculatorModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
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

proc myClamp(args: seq[float]): float =
    return clamp(args[1], args[0], args[2])

method synthesize(module: CalculatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =

    var varArray: array[4, float64]
    for i in 0..<module.inputs.len:
        if(module.inputs[i].moduleIndex < 0):
            varArray[i] = 0
            continue
        let moduleA = moduleList[module.inputs[i].moduleIndex]
        if(moduleA == nil):
            varArray[i] = 0
            continue
        varArray[i] = moduleA.synthesize(x, pin, moduleList, synthInfos)
    let e = newEvaluator()

    e.addVars(
        {
            "a": varArray[0],
            "b": varArray[1],
            "c": varArray[2],
            "d": varArray[3],
            
            "x": x,
            "fb": module.prev,
            "wl": synthInfos.waveDims.x.float,
            "wh": synthInfos.waveDims.y.float,

            "env": module.envelope.doAdsr(synthInfos.macroFrame),
            "est": module.envelope.start.float64,
            "ea1": module.envelope.attack.float64,
            "ep1": module.envelope.peak.float64,
            "ed1": module.envelope.decay.float64,
            "es1": module.envelope.sustain.float64,
            "ea2": module.envelope.attack2.float64,
            "ep2": module.envelope.peak2.float64,
            "ed2": module.envelope.decay2.float64,
            "es2": module.envelope.sustain2.float64,
            
            "flan": 495.0
        }
    )
    
    proc synth(args: seq[float]): float =
        if(args[0].int > 3 or args[0].int < 0): return 0
        if(module.inputs[args[0].int].moduleIndex < 0): return 0
        let moduleE = moduleList[module.inputs[args[0].int].moduleIndex]
        if(moduleE == nil): return 0 else: return moduleE.synthesize(args[1], pin, moduleList, synthInfos)

    e.addFunc("synth", synth, 2)
    e.addFunc("clamp", myClamp, 3)
    e.addFunc("avg", avg)

    var output = 0.0
    try:
        output = e.eval(module.formula)    
    except ValueError:
        module.prev = output
        return output
    output = if(isNaN(output)): 0.0 else: output
    module.prev = output
    return output
        

import ../serializationObject
import flatty

method serialize*(module: CalculatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.CALCULATOR, data: toFlatty(module))