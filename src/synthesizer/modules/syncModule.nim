import module
import ../globals
import ../utils/utils
import math

type
    SyncModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool = false

proc constructSyncModule*(): SyncModule =
    var module = new SyncModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: SyncModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0 else:
            if(not module.useAdsr): 
                return moduleA.synthesize(moduloFix(x * module.envelope.peak.float64, 2 * PI), module.inputs[0].pinIndex)
            else:
                return moduleA.synthesize(moduloFix(x * module.envelope.doAdsr(), 2 * PI), module.inputs[0].pinIndex)

import ../serializationObject
import flatty

method serialize*(module: SyncModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.SYNC, data: toFlatty(module))