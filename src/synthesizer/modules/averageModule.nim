import module
import ../globals
import ../utils/utils
import ../synthInfos
import ../synthInfos

type
    AverageModule* = ref object of SynthModule

proc constructAverageModule*(): AverageModule =
    var module = new AverageModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: AverageModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var output = 0.0
    var avg = 0.0

    for link in module.inputs:
        if(link.moduleIndex > -1):
            avg += 1.0
            let moduleA = moduleList[link.moduleIndex]
            if(moduleA == nil): continue
            output += moduleA.synthesize(x, link.pinIndex, moduleList, synthInfos)

    if(avg == 0.0): return 0 else: return output / avg

import ../serializationObject
import flatty

method serialize*(module: AverageModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AVERAGE, data: toFlatty(module))