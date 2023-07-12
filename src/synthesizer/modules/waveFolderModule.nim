import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    WaveFolderModule* = ref object of SynthModule
        waveFoldType*: int32 = 0

proc constructWaveFolderModule*(): WaveFolderModule =
    var module = new WaveFolderModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc linFold(x: float64): float64 =
    # var w = x
    # var l = w
    # if(w < -1): l = -2 - w
    # if(w > 1): l = 2 - w
    # if(l > 1 or l < -1):
    #     l = linFold(l)
    # return l
    let a = x * 0.25 + 0.75
    let r = moduloFix(a, 1)
    return abs(r * -4.0 + 2.0) - 1.0

proc vital(x: float64): float64 =
    let a = x * 0.25 + 0.75
    let r = moduloFix(a, 1)
    return abs(r * -4.0 + 2.0) - 1.0

proc overFlow(x: float64): float64 =
    if(x <= 1 and x >= -1): return x
    return moduloFix(x + 1, 2) - 1

proc waveFolding(x: float64, waveFoldType: int32): float64 =
    if(waveFoldType == 0):
        return sin(x)
    elif(waveFoldType == 1):
        return linFold(x)
    elif(waveFoldType == 2):
        return overFlow(x)

method synthesize*(module: WaveFolderModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0 else: return waveFolding(moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos), module.waveFoldType)

import ../serializationObject
import flatty

method serialize*(module: WaveFolderModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.WAVE_FOLDER, data: toFlatty(module))