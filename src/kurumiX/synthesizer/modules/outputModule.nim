import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    OutputModule* = ref object of SynthModule

proc constructOutputModule*(): OutputModule =
    var module = new OutputModule
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: OutputModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    # assert module.inputs[0].moduleIndex < 256
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 else: moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)

import ../serializationObject
import flatty

method serialize*(module: OutputModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.OUTPUT, data: toFlatty(module))