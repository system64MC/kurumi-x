import module
import ../utils/utils
import ../synthInfos
import ../globals
import math
import std/random

const squareTable = [1.0, -1.0]


type
    NoiseOscillatorModule* = ref object of SynthModule
        noiseMode*: int32

proc constructNoiseOscillatorModule*(): NoiseOscillatorModule =
    var module = new NoiseOscillatorModule
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

var lsfrSeed: uint16 = 0b01001_1010_1011_1010

proc lsfrShift(): void =
    lsfrSeed = (lsfrSeed shl 1) or (((lsfrSeed shr 13) xor (lsfrSeed shr 14)) and 1)

proc noise1BitLsfr(): float64 =
    lsfrShift()
    return float64(lsfrSeed and 1) * 2 - 1

proc noise8bitLsfr(): float64 =
    lsfrShift()
    return float64(lsfrSeed and 0xFF)/float64(0x7F) - 1

proc noiseRandom(): float64 =
    return rand(2.0) - 1.0


method synthesize(module: NoiseOscillatorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    case module.noiseMode:
    of 0:
        return noise1BitLsfr()
    of 1:
        return noise8bitLsfr()
    of 2:
        return noiseRandom()
    else:
        return noiseRandom()
    
import ../serializationObject
import flatty

method serialize*(module: NoiseOscillatorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.NOISE, data: toFlatty(module))