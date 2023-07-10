import module
import ../globals
import ../utils/utils
import math

type
    DualWaveModule* = ref object of SynthModule

proc constructDualWaveModule*(): DualWaveModule =
    var module = new DualWaveModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc moduloFix(a, b: float64): float64 =
    return ((a mod b) + b) mod b

method synthesize*(module: DualWaveModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    var moduleA: SynthModule = nil
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]
    
    if(moduleA == nil and moduleB == nil): return 0
    let x2 = moduloFix(x * 2, 2 * PI)
    if(x < PI):
        return if(moduleA != nil): moduleA.synthesize(x2, module.inputs[0].pinIndex, moduleList) else: 0.0
    else:
        return if(moduleB != nil): moduleB.synthesize(x2, module.inputs[1].pinIndex, moduleList) else: 0.0

import ../serializationObject
import flatty

method serialize*(module: DualWaveModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.DUAL_WAVE, data: toFlatty(module))