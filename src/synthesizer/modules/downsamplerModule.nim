import module
import ../globals
import ../utils/utils
import math

type
    DownsamplerModule* = ref object of SynthModule
        downsample*: float32 = 1.0

proc constructDownsamplerModule*(): DownsamplerModule =
    var module = new DownsamplerModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: DownsamplerModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0

    if(module.downsample >= 1): return moduleA.synthesize(x, module.inputs[0].pinIndex)

    var x1 = 0.0
    var res = 0.0
    let delta = (1 - module.downsample) * PI * 2

    while x1 < x:
        res = moduleA.synthesize(x1, module.inputs[0].pinIndex)
        x1 += delta
        
    return res

import ../serializationObject
import flatty

method serialize*(module: DownsamplerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.DOWNSAMPLER, data: toFlatty(module))