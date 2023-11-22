import utils
type
    SynthInfos* = ref object
        waveDims*: VecI32 = VecI32(x: 32, y: 15)
        oversample*: int32 = 4
        macroLen*: int32 = 64
        macroFrame*: int32 = 0
        lsfr*: uint16 = 0b01001_1010_1011_1010

    SynthInfosSerialize* = object
        waveDims*: VecI32
        oversample*: int32 = 4
        macroLen*: int32 = 64
        macroFrame*: int32 = 0

proc serializeSynthInfos*(infos: SynthInfos): SynthInfosSerialize =
    return SynthInfosSerialize(
        waveDims: infos.waveDims,
        oversample: infos.oversample,
        macroLen: infos.macroLen,
        macroFrame: infos.macroFrame
    )