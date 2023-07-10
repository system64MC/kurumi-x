import module
import ../globals
import ../utils/utils

type
    RectifierModule* = ref object of SynthModule

proc constructRectifierModule*(): RectifierModule =
    var module = new RectifierModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: RectifierModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0
    else:
        let output = moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList)
        if(output > 0): return output else: return 0.0

import ../serializationObject
import flatty

method serialize*(module: RectifierModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.RECTIFIER, data: toFlatty(module))