import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    QuadWaveAssemblerModule* = ref object of SynthModule

proc constructQuadWaveAssemblerModule*(): QuadWaveAssemblerModule =
    var module = new QuadWaveAssemblerModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1),
                    Link(moduleIndex: -1, pinIndex: -1)
                    ]
    return module


method synthesize*(module: QuadWaveAssemblerModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var moduleA: SynthModule = nil
    if(x < PI/4):
        if(module.inputs[0].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[0].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0

    if(x >= PI/4 and x < PI/2):
        if(module.inputs[1].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[1].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0

    if(x >= PI/2 and x < (PI/2 + PI/4)):
        if(module.inputs[2].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[2].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[2].pinIndex, moduleList, synthInfos) else: 0

    if(x >= (PI/2 + PI/4) and x < PI):
        if(module.inputs[3].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[3].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[3].pinIndex, moduleList, synthInfos) else: 0

    if(x >= (PI) and x < (PI + PI/4)):
        if(module.inputs[4].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[4].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[4].pinIndex, moduleList, synthInfos) else: 0

    if(x >= (PI + PI/4) and x < (PI + PI/2)):
        if(module.inputs[5].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[5].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[5].pinIndex, moduleList, synthInfos) else: 0

    if(x >= (PI + PI/2) and x < (PI + PI/2 + PI/4)):
        if(module.inputs[6].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[6].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[6].pinIndex, moduleList, synthInfos) else: 0

    if(x >= (PI + PI/2 + PI/4) and x < 2 * PI):
        if(module.inputs[7].moduleIndex < 0): return 0
        moduleA = moduleList[module.inputs[7].moduleIndex]
        return if(moduleA != nil): moduleA.synthesize(x, module.inputs[7].pinIndex, moduleList, synthInfos) else: 0

        # if(x < module.mirrorPlace): return moduleA.synthesize(moduloFix(x2, 1)) else: return moduleA.synthesize((module.mirrorPlace - 2 * x) mod 1)

import ../serializationObject
import flatty

method serialize*(module: QuadWaveAssemblerModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.QUAD_WAVE_ASM, data: toFlatty(module))