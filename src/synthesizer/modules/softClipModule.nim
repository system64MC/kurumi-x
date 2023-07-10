import module
import ../globals
import ../utils/utils
import math

type
    SoftClipModule* = ref object of SynthModule

proc constructSoftClipModule*(): SoftClipModule =
    var module = new SoftClipModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: SoftClipModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0 else: return (2.0/(1 +  pow(E, (-2 * (moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList)))))) - 1

import ../serializationObject
import flatty

method serialize*(module: SoftClipModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.SOFT_CLIP, data: toFlatty(module))