import module
import ../globals
import ../utils/utils
import outputModule

const GRID_SIZE_X = 16
const GRID_SIZE_Y = 16

type
    BoxModule* = ref object of SynthModule
        moduleList*: array[GRID_SIZE_X * GRID_SIZE_Y, SynthModule]
        name*: string = "My Box"
        inputIndex*: uint16 = 0
        outputIndex*: uint16 = 7

proc constructBoxModule*(): BoxModule =
    var module = new BoxModule
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
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    module.moduleList[7] = OutputModule()
    return module

method synthesize(module: BoxModule, x: float64, pin: int): float64 =

    let outModule = module.moduleList[module.outputIndex].OutputModule
    # echo outModule.inputs[0].pinIndex

    return 0
    # let val = outModule.synthesize(x, outModule.inputs[0].pinIndex)

import ../serializationObject
import flatty

type
    BoxModuleSerialize* = object
        inputIndex*: uint16
        outputIndex*: uint16
        data*: array[GRID_SIZE_X * GRID_SIZE_Y, ModuleSerializationObject]
        inputs*: seq[Link]
        outputs*: seq[Link]
        name*: string

method serialize*(module: BoxModule): ModuleSerializationObject =
    var serialArray: array[GRID_SIZE_X * GRID_SIZE_Y, ModuleSerializationObject]
    for i in 0..<(GRID_SIZE_X * GRID_SIZE_Y):
        let m = module.moduleList[i]
        if(m == nil): continue
        serialArray[i] = m.serialize()
    
    let sData = BoxModuleSerialize(
        inputIndex: module.inputIndex,
        outputIndex: module.outputIndex,
        data: serialArray,
        inputs: module.inputs,
        outputs: module.outputs,
        name: module.name
    )
    return ModuleSerializationObject(mType: ModuleType.BOX, data: toFlatty(sData))