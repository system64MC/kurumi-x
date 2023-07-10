import module
import ../globals
import ../utils/utils
import math

type
    PdModule* = ref object of SynthModule
        xEnvelope*: Adsr = Adsr(peak: 0.5)
        yEnvelope*: Adsr = Adsr(peak: 0.5)
        useAdsrX* : bool = false
        useAdsrY* : bool = false

proc constructPdModule*(): PdModule =
    var module = new PdModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc linearInterpolation(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))  

method synthesize*(module: PdModule, x: float64, pin: int, moduleList: array[256, SynthModule]): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = moduleList[module.inputs[0].moduleIndex]
    if(moduleA == nil): 
        return 0 
    else:
        
        let distortX = if(not module.useAdsrX): module.xEnvelope.peak else: module.xEnvelope.doAdsr()
        let distortY = if(not module.useAdsrY): module.yEnvelope.peak else: module.yEnvelope.doAdsr()

        if(x < distortX * 2 * PI): 
            # moduleA.synthesize(linearInterpolation(0, module.distortY, module.distortX, 1.0, x))
            return moduleA.synthesize(linearInterpolation(0, 0, distortX, distortY, x / (2 * PI)) * 2 * PI, module.inputs[0].pinIndex, moduleList)
        else:
            return moduleA.synthesize(linearInterpolation(distortX, distortY, 1.0, 1.0, x / (2 * PI)) * 2 * PI, module.inputs[0].pinIndex, moduleList)

import ../serializationObject
import flatty

method serialize*(module: PdModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.PHASE_DIST, data: toFlatty(module))