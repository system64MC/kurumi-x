import module
import ../globals
import ../utils/utils
import math

type
    ClipperModule* = ref object of SynthModule
        clipMax*: float32 = 1.0
        clipMin*: float32 = -1.0

proc constructClipperModule*(): ClipperModule =
    var module = new ClipperModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: ClipperModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 else: return min(max(moduleA.synthesize(x, module.inputs[0].pinIndex), module.clipMin), module.clipMax)

import ../serializationObject
import flatty

method serialize*(module: ClipperModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.CLIPPER, data: toFlatty(module))