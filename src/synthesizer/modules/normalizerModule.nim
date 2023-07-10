import module
import ../globals
import ../utils/utils
import math

type
    NormalizerModule* = ref object of SynthModule
        min: float64 = 0.0
        max: float64 = 0.0

proc constructNormalizerModule*(): NormalizerModule =
    var module = new NormalizerModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)
    ]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: NormalizerModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0
    let step = (2 * PI)/(synthContext.oversample.float64 * synthContext.waveDims.x.float64)
    var x1 = 0.0


    # for i in 0..<synthContext.waveDims.x * synthContext.oversample:
    #         let res = moduleA.synthesize((i.float64) * PI * 2 / synthContext.waveDims.x.float64, module.inputs[0].pinIndex)
    #         if(res > module.max): module.max = res
    #         if(res < module.max): module.max = res

    if(module.update):
        if(moduleA == nil):
            module.max = 0
            module.min = 0
        else:
            module.max = 0
            module.min = 0
            while x1 < 2 * PI:
                let res = moduleA.synthesize(x1, module.inputs[0].pinIndex, moduleList)
                if(res > module.max): module.max = res
                if(res < module.min): module.min = res
                x1 += step
        module.update = false

    if(moduleA == nil):
        return 0.0

    let norm = max(abs(module.max), abs(module.min))

    return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList) * (1 / norm)
    # return moduleA.synthesize(x, module.inputs[0].pinIndex)

import ../serializationObject
import flatty

method serialize*(module: NormalizerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.NORMALIZER, data: toFlatty(module))