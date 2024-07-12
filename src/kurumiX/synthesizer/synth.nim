import math
import modules/module
import ../../common/utils
import ../../common/synthInfos
import ../../common/genericSynth

# We want at most 256 modules.
const GRID_SIZE_X* = 16
const GRID_SIZE_Y* = 16




type    
    Synth* = ref object of GenericSynth
        moduleList*: array[GRID_SIZE_X * GRID_SIZE_Y, SynthModule]
        outputIndex*: uint16 = 1


        # outputFloat*: array[4096 * 8, float64]
        # outputInt*: array[4096, int32]

    # outWave = seq[int32]







    


# method synthesize(module: MultiplyModule, x: float64): float64 =
#     let a = if(module.inputs[0] != nil): module.inputs[0].synthesize(x) else: 0
#     let b = if(module.inputs[1] != nil): module.inputs[1].synthesize(x) else: 0
#     return a * b

# method synthesize(module: SubstractModule, x: float64): float64 =
#     let a = if(module.inputs[0] != nil): module.inputs[0].synthesize(x) else: 0
#     let b = if(module.inputs[1] != nil): module.inputs[1].synthesize(x) else: 0
#     return a - b
    

    