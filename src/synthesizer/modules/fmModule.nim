import module
import ../globals
import ../utils/utils

type
    FmodModule* = ref object of SynthModule

proc constructFmodModule*(): FmodModule =
    var module = new FmodModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: FmodModule, x: float64, pin: int): float64 =
    let moduleB = if(module.inputs[1].moduleIndex > -1): synthContext.moduleList[module.inputs[1].moduleIndex] else: return 0
    let moduleA = if(module.inputs[0].moduleIndex > -1): synthContext.moduleList[module.inputs[0].moduleIndex] else: nil

    let modulation = if(moduleA == nil): 0.0 else: moduleA.synthesize(x, module.inputs[0].pinIndex)

    return moduleB.synthesize(x + modulation * 6, module.inputs[1].pinIndex)

import ../serializationObject
import flatty

method serialize*(module: FmodModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.FM, data: toFlatty(module))