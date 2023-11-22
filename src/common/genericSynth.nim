import synthInfos

type
    GenericSynth* = ref object of RootObj
        outputFloat*: array[4096 * 8, float64]
        outputInt*: array[4096, int32]
        synthInfos*: SynthInfos = SynthInfos()

method synthesize*(synth: GenericSynth) {.base, gcsafe.} =
    return
