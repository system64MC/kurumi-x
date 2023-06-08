import module
import ../globals
import ../utils/utils
import math

type
    UnisonModule* = ref object of SynthModule
        unison*: int32

proc constructUnisonModule*(): UnisonModule =
    var module = new UnisonModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc getPhase(unisonLevel: float64): float64 =
    var mac = synthContext.macroFrame.float64
    var macLen = synthContext.macroLen.float64
    let detune = pow(-1, unisonLevel + 1) * ceil(unisonLevel / 2)
    # Anti-divide by 0
    if(macLen < 2): macLen = 2
    return mac.float64 / (macLen - 1) * detune

method synthesize*(module: UnisonModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0
    else:
        if(module.unison < 1):
            return moduleA.synthesize(x, module.inputs[0].pinIndex)
        var sum = 0.0
        var divider = 0.0
        for i in 0..module.unison:
            divider += 1.0
            sum += moduleA.synthesize(moduloFix(x + getPhase(i.float64) * PI * 2, 2 * PI), module.inputs[0].pinIndex)

        return sum / divider

import ../serializationObject
import flatty

method serialize*(module: UnisonModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.UNISON, data: toFlatty(module))