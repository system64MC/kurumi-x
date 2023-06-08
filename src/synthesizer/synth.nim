import math
import modules/module
import utils/utils

# We want at most 256 modules.
const GRID_SIZE_X* = 16
const GRID_SIZE_Y* = 16

type
    

    Synth* = object
        moduleList*: array[GRID_SIZE_X * GRID_SIZE_Y, SynthModule]
        waveDims*: VecI32 = VecI32(x: 32, y: 15)
        oversample*: int32 = 4
        outputIndex*: uint16 = 1
        macroLen*: int32 = 64
        macroFrame*: int32 = 0
    
    outWave = seq[int32]







    


# method synthesize(module: MultiplyModule, x: float64): float64 =
#     let a = if(module.inputs[0] != nil): module.inputs[0].synthesize(x) else: 0
#     let b = if(module.inputs[1] != nil): module.inputs[1].synthesize(x) else: 0
#     return a * b

# method synthesize(module: SubstractModule, x: float64): float64 =
#     let a = if(module.inputs[0] != nil): module.inputs[0].synthesize(x) else: 0
#     let b = if(module.inputs[1] != nil): module.inputs[1].synthesize(x) else: 0
#     return a - b
    

    