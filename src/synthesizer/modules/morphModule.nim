import module
import ../globals
import ../utils/utils

type
    MorphModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 0.0)
        useAdsr*: bool = false

proc constructMorphModule*(): MorphModule =
    var module = new MorphModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        ]
    return module

proc lerp(x, y, a: float64): float64 =
    return x*(1-a) + y*a  

method synthesize*(module: MorphModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    var valA = 0.0
    var moduleA: SynthModule = nil
    var valB = 0.0
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]

    if(moduleA != nil): valA = moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList)
    if(moduleB != nil): valB = moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList)

    return lerp(valA, valB, if(not module.useAdsr): module.envelope.peak else: module.envelope.doAdsr())

import ../serializationObject
import flatty

method serialize*(module: MorphModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.MORPHER, data: toFlatty(module))