import module
import ../globals
import ../utils/utils
import ../synthInfos
import math

type
    AvgFilterModule* = ref object of SynthModule
        envelope*: Adsr = Adsr(peak: 1.0)
        useAdsr*: bool
        normalize*: bool = false
        buffer*: array[4096 * 8, float64]
        min*: float64 = 0
        max*: float64 = 0

proc constructAvgFilterModule*(): AvgFilterModule =
    var module = new AvgFilterModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

const LENGTH = 4096.0

method synthesize*(module: AvgFilterModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    let window = module.envelope.doAdsr(synthInfos.macroFrame).floor.int
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]


    if(module.update):
        if(moduleA == nil):
            for i in 0..<module.buffer.len:
                module.buffer[i] = 0
                module.max = 0
                module.min = 0
        else:
            module.max = 0
            module.min = 0
            for a in 0..<LENGTH.int:
                var res = 0.0
                const RATIO = 1.0/(1024.0)
                let r = (a.float64 / LENGTH) * 2 * PI
                for i in -window..window:
                    res += moduleA.synthesize(moduloFix((r + (i.float64 * RATIO * 2 * PI)), 2 * PI), module.inputs[0].pinIndex, moduleList, synthInfos)
                
                let f = res / ((window * 2) + 1).float64                
                module.buffer[a] = f
                module.max = max(module.max, f)
                module.min = min(module.min, f)
                # echo "Max : " & $module.max
                # echo "Min : " & $module.min
        module.update = false

    if(moduleA == nil): return 0

    let delta = 1.0 / LENGTH
    let output = module.buffer[math.floor(moduloFix(x / (2 * PI), 1)/delta).int]
    if(module.normalize):
        let norm = max(abs(module.max), abs(module.min))
        if norm == 0: return output
        return output * (1 / norm)
    return output
    
    
    
import ../serializationObject
import flatty

method serialize*(module: AvgFilterModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AVG_FILTER, data: toFlatty(module))