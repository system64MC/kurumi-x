import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    DcOffsetModule* = ref object of SynthModule
        offset*: float32 = 0.0

proc constructDcOffsetModule*(): DcOffsetModule =
    var module = new DcOffsetModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: DcOffsetModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0 else: return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) + module.offset

import ../serializationObject
import flatty

method serialize*(module: DcOffsetModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.DC_OFFSET, data: toFlatty(module))