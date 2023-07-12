import module
import ../globals
import ../utils/utils
import ../synthInfos

type
    FmProModule* = ref object of SynthModule
        # matrix*: array[6, array[6, bool]] = [
        #     [true , false, false, false, false, false],
        #     [false, true , false, false, false, false],
        #     [false, false, true , false, false, false],
        #     [false, false, false, true , false, false],
        #     [false, false, false, false, true , false],
        #     [false, false, false, false, false, true ],
        # ]
        modMatrix*: array[8 * 8, float32] = [
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
        ]
        samples*: array[8, float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

proc constructFmProModule*(): FmProModule =
    var module = new FmProModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1),
        ]
    return module

method synthesize(module: FmProModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =

    # for operator in 0..<6:
    #     var sum = 0.0
    #     for modulator in 0..<6:
    #         if module.matrix[operator][modulator]:
    #             sum += module.samples[modulator]
    #     let modModule = if(module.inputs[operator].moduleIndex > -1): moduleList[module.inputs[operator].moduleIndex] else: nil
    #     module.samples[operator] = if(modModule == nil): 0 else: modModule.synthesize(x + sum * 6, module.inputs[operator].pinIndex)

    var index = 0
    for operator in 0..<8:
        var sum = 0.0
        for modulator in 0..<8:
            index = operator * 8 + modulator

            if module.modMatrix[index] > 0.0:
                sum += module.samples[modulator] * module.modMatrix[index]
        let modModule = if(module.inputs[operator].moduleIndex > -1): moduleList[module.inputs[operator].moduleIndex] else: nil
        module.samples[operator] = if(modModule == nil): 0 else: modModule.synthesize(x + sum * 6, module.inputs[operator].pinIndex, moduleList, synthInfos)

    # for operator in 0..<6:
    #     var sum = 0.0
    #     for modulator in 0..<6:
    #         if module.matrix[operator][modulator]:
    #             sum += samples[modulator]
    #     let modModule = if(module.inputs[operator].moduleIndex > -1): moduleList[module.inputs[operator].moduleIndex] else: nil
    #     samples[operator] = if(modModule == nil): 0 else: modModule.synthesize(x + sum * 6, pin)
    
    return module.samples[pin]
    # let modulation = if(moduleA == nil): 0.0 else: moduleA.synthesize(x)

    # return moduleB.synthesize(x + modulation)

import ../serializationObject
import flatty

method serialize*(module: FmProModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.FM_PRO, data: toFlatty(module))