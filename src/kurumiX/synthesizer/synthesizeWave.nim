# import globals
import modules/outputModule
import modules/boxModule
import modules/module
import math
import strutils
# import print
# import kissfft/kissfft
# import fourierTransform
import resampling
import synth
import ../../common/genericSynth
import ../../common/synthInfos

proc update(moduleList: array[256, SynthModule]): void =
    for m in moduleList:
        if(m == nil): continue
        m.update = true
        if(m of BoxModule):
            echo "Updating Box"
            update((m.BoxModule).moduleList)

proc redrawWaves(moduleList: array[256, SynthModule], infos: SynthInfos): void =
    for m in moduleList:
        if(m == nil): continue
        # {.cast(gcsafe).}:
        for i in 0..<128:
            let sample = -m.synthesize(i.float64 * PI * 2 / 128.0, 0, moduleList, infos)
            m.waveDisplay[i] = sample

method synthesize*(synth: Synth, redraw: bool = true) {.gcsafe.} =

    # for m in synth.moduleList:
    #     if(m == nil): continue
    #     m.update = true

    # update(synth.moduleList)
    update(synth.moduleList)
    # print(synth)

    let outModule = synth.moduleList[synth.outputIndex].OutputModule
    # echo outModule.inputs[0].pinIndex

    let overSampleValue = 1.0/synth.synthInfos.oversample.float64

    for i in 0..<synth.synthInfos.waveDims.x:
        var sum = 0.0
        var j = 0.0
        while(j < 1):
            sum += outModule.synthesize((i.float64 + j) * PI * 2 / synth.synthInfos.waveDims.x.float64, outModule.inputs[0].pinIndex, synth.moduleList, synth.synthInfos) * overSampleValue
            j += overSampleValue
        synth.outputFloat[i] = sum

    # fourierTransform(outputFloat.addr, synth.waveDims.x)

    for i in 0..<synth.synthInfos.waveDims.x:
        var value = min(max(synth.outputFloat[i], -1.0), 1.0) + 1

        synth.outputInt[i] = round(value * (synth.synthInfos.waveDims.y.float64 / 2.0)).int32

    if(redraw): redrawWaves(synth.moduleList, synth.synthInfos)

# proc synthesize2*(synth: var Synth): void =
#     update(synth.moduleList)
#     # print(synth)
# 
#     let outModule = synth.moduleList[synth.outputIndex].OutputModule
#     # echo outModule.inputs[0].pinIndex
# 
#     let overSampleValue = 1.0/synth.synthInfos.oversample.float64
# 
#     for i in 0..<(4096 * 8):
#         var sum = 0.0
#         sum += outModule.synthesize((i.float64) * PI * 2 / (4096 * 8), outModule.inputs[0].pinIndex, synth.moduleList, synth.synthInfos)
#         synth.outputFloat[i] = sum
# 
#     # fourierTransform(outputFloat.addr, synth.waveDims.x)
# 
#     resample()

proc generateWaveStr*(synth: Synth, hex: bool = false): string =
    var str = ""
    for i in 0..<synth.synthInfos.waveDims.x:
        if(hex):
            var num = $(synth.outputInt[i]).toHex().strip(true, chars = {'0'})
            if(num == ""): num = "0"
            str &= num & " "
        else:
            str &= $synth.outputInt[i] & " "

    return str & ";"

proc generateSeqStr*(synth: Synth, hex: bool = false): string =
    let macroBackup = synth.synthInfos.macroFrame
    var outStr = ""
    for mac in 0..<synth.synthInfos.macroLen:
        synth.synthInfos.macroFrame = mac
        synth.synthesize()
        outStr &= synth.generateWaveStr(hex) & "\n"
    synth.synthInfos.macroFrame = macroBackup
    synth.synthesize()
    return outStr