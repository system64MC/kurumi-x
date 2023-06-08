import module
import ../globals
import ../utils/utils
import math

type
    OutputModule* = ref object of SynthModule

proc constructOutputModule*(): OutputModule =
    var module = new OutputModule
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: OutputModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 else: moduleA.synthesize(x, module.inputs[0].pinIndex)

import ../serializationObject
import flatty

method serialize*(module: OutputModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.OUTPUT, data: toFlatty(module))