import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    LfoModule* = ref object of SynthModule
        lfoType*: int32 = 0
        frequency*: int32 = 0
        lfoMode*: int32 = 0
        intensity*: float32 = 0

    LfoType* = enum
        SINE,
        TRIANGLE,
        SAW,
        SQUARE,
        CUSTOM

    LfoMode* = enum
        VIBBATO,
        TREMOLO

proc constructLfoModule*(): LfoModule =
    var module = new LfoModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        ]
    return module

method getLfoValue(module: LfoModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 {.base.} =
    var res = 0.0
    case module.lfoType.LfoType
        of SINE:
            res = sin((synthInfos.macroFrame.float64/synthInfos.macroLen.float64) * 2 * PI * module.frequency.float64)
        of TRIANGLE:
            res = arcsin(sin((synthInfos.macroFrame.float64/synthInfos.macroLen.float64) * 2 * PI * module.frequency.float64)) / (PI * 0.5)
        of SAW:
            res = arctan(tan((synthInfos.macroFrame.float64/synthInfos.macroLen.float64) * 2 * PI * module.frequency.float64)) / (math.Pi * 0.5)
        of SQUARE:
            let val = ((synthInfos.macroFrame.float64/synthInfos.macroLen.float64) * 2 * module.frequency.float64)
            res = if(moduloFix(val, 2) < (0.5 * 2)): 1 else: -1
        of CUSTOM:
            if(module.inputs[1].moduleIndex > -1):
                let moduleB = moduleList[module.inputs[1].moduleIndex]
                let val = (synthInfos.macroFrame.float64 * PI * 2) / synthInfos.macroLen.float64
                res = if(moduleB == nil): 0 else: moduleB.synthesize(moduloFix(val * module.frequency.float64, 2 * PI), module.inputs[1].pinIndex, moduleList, synthInfos)

    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0
    
    if(module.lfoMode.LfoMode == LfoMode.VIBBATO): 
        res = res * (module.intensity / 2)
        return moduleA.synthesize(x + res * PI * 2, module.inputs[0].pinIndex, moduleList, synthInfos)
    else:
        res = max(((res / 2) + 1) * module.intensity, 0)
        return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) * res

method synthesize*(module: LfoModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    return module.getLfoValue(x, module.inputs[0].pinIndex, moduleList, synthInfos)

import ../serializationObject
import flatty

method serialize*(module: LfoModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.LFO, data: toFlatty(module))