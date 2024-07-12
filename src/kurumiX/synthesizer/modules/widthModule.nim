import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    WidthModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool = false

proc constructWidthModule*(): WidthModule =
    var module = new WidthModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: WidthModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0 else:
            let a = module.envelope.doAdsr(synthInfos.macroFrame)
            if(a == 0): return 0
            let ratio = 1.0 / a
            let myMod = moduloFix(x * ratio, 2 * PI)
            let x2 = moduloFix(x, 2 * PI)
            if(x2 < (PI * 2) * a):
                return moduleA.synthesize(myMod, module.inputs[0].pinIndex, moduleList, synthInfos)
            return 0
import ../serializationObject
import flatty

method serialize*(module: WidthModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.WIDTH, data: toFlatty(module))