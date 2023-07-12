import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    QuantizerModule* = ref object of SynthModule
        quantizationEnvelope*: Adsr = Adsr(peak: 1.0)
        quatization*: float32 = 1.0
        useAdsr*: bool = false

proc constructQuantizerModule*(): QuantizerModule =
    var module = new QuantizerModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module


method synthesize(module: QuantizerModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0

    let quantization = if(module.useAdsr): module.quantizationEnvelope.doAdsr(synthInfos.macroFrame) else: module.quantizationEnvelope.peak

    if(quantization >= 1): return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)

    var x1 = 0.0
    var res = 0.0
    var outp = 0.0
    const delta = 1.0 / 4096.0

    res = moduleA.synthesize(x, pin, moduleList, synthInfos)
    if(res < 0):
        while x1 > res:
            outp = x1
            x1 -= 1 - quantization
        return outp

    while x1 < res:
        outp = x1
        x1 += 1 - quantization
    return outp

import ../serializationObject
import flatty

method serialize*(module: QuantizerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.QUANTIZER, data: toFlatty(module))