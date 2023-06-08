import module
import ../globals
import ../utils/utils

type
    AmplifierModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool

proc constructAmplifierModule*(): AmplifierModule =
    var module = new AmplifierModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module



method synthesize*(module: AmplifierModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]
    if(not module.useAdsr):
        if(moduleA == nil): return 0 else: return moduleA.synthesize(x, module.inputs[0].pinIndex) * module.envelope.peak
    if(moduleA == nil): return 0 else: return moduleA.synthesize(x, module.inputs[0].pinIndex) * module.envelope.doAdsr()
    
import ../serializationObject
import flatty

method serialize*(module: AmplifierModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AMPLIFIER, data: toFlatty(module))