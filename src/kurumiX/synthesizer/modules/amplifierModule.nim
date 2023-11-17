import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos

type
    AmplifierModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool

proc constructAmplifierModule*(): AmplifierModule =
    var module = new AmplifierModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module



method synthesize*(module: AmplifierModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): return 0 else: return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) * module.envelope.doAdsr(synthInfos.macroFrame)
    
import ../serializationObject
import flatty

method serialize*(module: AmplifierModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AMPLIFIER, data: toFlatty(module))