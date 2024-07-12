import math
import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos

type
    AmpMaskModule* = ref object of SynthModule
        amps*: array[32, bool] = [
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true 
        ]

proc constructAmpMaskModule*(): AmpMaskModule =
    var module = new AmpMaskModule
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: AmpMaskModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let p = x / (PI * 2.0)
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(not module.amps[(p * 32).int] or moduleA == nil): return 0.0
    return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)

import ../serializationObject
import flatty

method serialize*(module: AmpMaskModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AMP_MASK, data: toFlatty(module))