import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos

type
    MixerModule* = ref object of SynthModule

proc constructMixerModule*(): MixerModule =
    var module = new MixerModule
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

method synthesize(module: MixerModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var output = 0.0

    for link in module.inputs:
        if(link.moduleIndex > -1):
            let module = moduleList[link.moduleIndex]
            if(module == nil): continue
            output += module.synthesize(x, link.pinIndex, moduleList, synthInfos)

    return output

import ../serializationObject
import flatty

method serialize*(module: MixerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.MIXER, data: toFlatty(module))