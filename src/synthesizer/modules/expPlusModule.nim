import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    ExpPlusModule* = ref object of SynthModule

proc constructExpPlusModule*(): ExpPlusModule =
    var module = new ExpPlusModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: ExpPlusModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
    let moduleB = if(module.inputs[1].moduleIndex > -1): moduleList[module.inputs[1].moduleIndex] else: nil

    let base = moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)
    let exp = if(moduleB == nil): 1.0 else: moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos)

    return pow(abs(base), abs(exp)).copySign(base)

import ../serializationObject
import flatty

method serialize*(module: ExpPlusModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.EXP_PLUS, data: toFlatty(module))