import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos

type
    RectifierModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 0.0)
        negativePositive*: uint8 = 0
        useAdsr*: bool

proc constructRectifierModule*(): RectifierModule =
    var module = new RectifierModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: RectifierModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0.0
    else:
        let output = moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)
        if(module.negativePositive == 0): # if negative
            if(output > 0.0): return output else: return module.envelope.doAdsr(synthInfos.macroFrame)
        else: # positive
            if(output < 0.0): return output else: return module.envelope.doAdsr(synthInfos.macroFrame)
import ../serializationObject
import flatty

method serialize*(module: RectifierModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.RECTIFIER, data: toFlatty(module))