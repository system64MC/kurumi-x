import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
type
    MultModule* = ref object of SynthModule

proc constructMultModule*(): MultModule =
    var module = new MultModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: MultModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var moduleA: SynthModule = nil
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]
    
    if(moduleA == nil and moduleB == nil): return 0

    let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 1.0
    let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 1.0

    return a * b

import ../serializationObject
import flatty

method serialize*(module: MultModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.MULT, data: toFlatty(module))