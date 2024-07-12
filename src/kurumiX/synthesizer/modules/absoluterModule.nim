import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import ../serializationObject
import flatty

type
    AbsoluterModule* = ref object of SynthModule

proc constructAbsoluterModule*(): AbsoluterModule =
    var module = new AbsoluterModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: AbsoluterModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0.0 else: return abs(moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos))

method serialize*(module: AbsoluterModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.ABSOLUTER, data: toFlatty(module))