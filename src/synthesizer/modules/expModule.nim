import module
import ../globals
import ../utils/utils
import math

type
    ExpModule* = ref object of SynthModule
        exponent*: float32 = 1.0

proc constructExpModule*(): ExpModule =
    var module = new ExpModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: ExpModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil):
        return 0 else:
            let output = pow(moduleA.synthesize(x, module.inputs[0].pinIndex), module.exponent)
            if(isNaN(output)): return 0 else: return output

import ../serializationObject
import flatty

method serialize*(module: ExpModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.EXPONENT, data: toFlatty(module))