import module
import ../globals
import ../utils/utils
import math

type
    ChordModule* = ref object of SynthModule
        mults*: array[8, int32] = [1, 0, 0, 0, 0, 0, 0, 0]

proc constructChordModule*(): ChordModule =
    var module = new ChordModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: ChordModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0
    else:
        var divider = 0.0
        var sum = 0.0
        for i in module.mults:
            if(i == 0): continue
            divider += 1.0
            sum += moduleA.synthesize(moduloFix(x * i.float64, 2 * PI), module.inputs[0].pinIndex, moduleList)

        if(divider == 0.0): return divider
        return sum / divider
        # if(x < module.mirrorPlace): return moduleA.synthesize(moduloFix(x2, 1)) else: return moduleA.synthesize((module.mirrorPlace - 2 * x) mod 1)

import ../serializationObject
import flatty

method serialize*(module: ChordModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.CHORD, data: toFlatty(module))