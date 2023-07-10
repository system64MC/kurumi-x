import module
import ../globals
import ../utils/utils
import math

type
    DownsamplerModule* = ref object of SynthModule
        downsampleEnvelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool = false

proc constructDownsamplerModule*(): DownsamplerModule =
    var module = new DownsamplerModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: DownsamplerModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0

    let downsample = if(module.useAdsr): module.downsampleEnvelope.doAdsr() else: module.downsampleEnvelope.peak

    if(downsample >= 1): return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList)

    var x1 = 0.0
    var res = 0.0
    let delta = (1 - downsample) * PI * 2

    while x1 < x:
        res = moduleA.synthesize(x1, module.inputs[0].pinIndex, moduleList)
        x1 += delta
        
    return res

import ../serializationObject
import flatty

method serialize*(module: DownsamplerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.DOWNSAMPLER, data: toFlatty(module))