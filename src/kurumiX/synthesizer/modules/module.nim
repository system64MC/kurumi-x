import ../../../common/utils
import ../../../common/synthInfos
import ../serializationObject
import math

type
    SynthModule* = ref object of RootObj
        inputs*  : seq[Link]
        outputs* : seq[Link]
        update*: bool = true
        waveDisplay*: array[128, float32]


method synthesize*(module: SynthModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 {.base.} =
    return x

method updateDisplay*(module: SynthModule, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos) {.base.} =
    for i in 0..<256.int:
        let sample = -module.synthesize(i.float64 * PI * 2.0 / 256.0, 0, moduleList, synthInfos)
        module.waveDisplay[i] = sample.float32
    return

method serialize*(module: SynthModule): ModuleSerializationObject {.base.} =
    return ModuleSerializationObject(mType: ModuleType.NULL, data: "")