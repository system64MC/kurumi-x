import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    SplitterModule* = ref object of SynthModule

proc constructSplitterModule*(): SplitterModule =
    var module = new SplitterModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)
    ]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc linFold(x: float64): float64 =
    var w = x
    var l = w
    if(w < -1): l = -2 - w
    if(w > 1): l = 2 - w
    if(l > 1 or l < -1):
        l = linFold(l)
    return l

method synthesize*(module: SplitterModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0 else: return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)

import ../serializationObject
import flatty

method serialize*(module: SplitterModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.SPLITTER, data: toFlatty(module))