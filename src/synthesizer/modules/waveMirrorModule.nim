import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    WaveMirrorModule* = ref object of SynthModule
        mirrorPlace*: float32 = 0.5

proc constructWaveMirrorModule*(): WaveMirrorModule =
    var module = new WaveMirrorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module


method synthesize*(module: WaveMirrorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0
    else:
        let x2 = x * 2
        let x3 = -1 + x
        let a = 1 - module.mirrorPlace
        if(x < PI): return moduleA.synthesize(moduloFix(x2, 2 * PI), module.inputs[0].pinIndex, moduleList, synthInfos) else: return moduleA.synthesize(moduloFix(-(-2 * PI + x2), 2 * PI), module.inputs[0].pinIndex, moduleList, synthInfos)
        # if(x < module.mirrorPlace): return moduleA.synthesize(moduloFix(x2, 1)) else: return moduleA.synthesize((module.mirrorPlace - 2 * x) mod 1)

import ../serializationObject
import flatty

method serialize*(module: WaveMirrorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.MIRROR, data: toFlatty(module))