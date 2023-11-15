import module
import ../globals
import ../utils/utils
import ../synthInfos
import ../synthInfos
import math

type
    ExpModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool

proc constructExpModule*(): ExpModule =
    var module = new ExpModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: ExpModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 
    let exp = module.envelope.doAdsr(synthInfos.macroFrame)
    let val = moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)
    let output = pow(abs(val), exp).copySign(val)
    if(isNaN(output)): return 0 else: return output

import ../serializationObject
import flatty

method serialize*(module: ExpModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.EXPONENT, data: toFlatty(module))