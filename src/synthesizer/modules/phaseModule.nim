import module
import ../globals
import ../utils/utils
import math

type
    PhaseModule* = ref object of SynthModule
        phase*: float32 = 0.0
        detune*: int32 = 0

proc constructPhaseModule*(): PhaseModule =
    var module = new PhaseModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method getPhase(module: PhaseModule): float64 {.base.} =
    var mac = synthContext.macroFrame.float64
    var macLen = synthContext.macroLen.float64

    # Anti-divide by 0
    if(macLen < 2): macLen = 2
    return mac.float64 / (macLen - 1) * module.detune.float64

method synthesize*(module: PhaseModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 else: return moduleA.synthesize(moduloFix(x + module.phase * 2 * PI  + module.getPhase() * PI * 2, 2 * PI), module.inputs[0].pinIndex, moduleList)

import ../serializationObject
import flatty

method serialize*(module: PhaseModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.PHASE, data: toFlatty(module))