import math
import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos

type
    PhaseMaskModule* = ref object of SynthModule
        phaseMask*: uint32 = 0xFF_FF_FF_FF.uint32
        phaseBools*: array[32, bool] = [
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true, 
            true, true, true, true, true, true, true, true 
        ]

proc constructPhaseMaskModule*(): PhaseMaskModule =
    var module = new PhaseMaskModule
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: PhaseMaskModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    var p = x / (PI * 2.0)
    p = float64((p * 0x1_00_00_00_00.float).uint32 and module.phaseMask) / 0x1_00_00_00_00.float
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0
    return moduleA.synthesize(p * PI * 2.0, module.inputs[0].pinIndex, moduleList, synthInfos)

import ../serializationObject
import flatty

method serialize*(module: PhaseMaskModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.PHASE_MASK, data: toFlatty(module))