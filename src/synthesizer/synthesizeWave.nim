import globals
import modules/outputModule
import modules/boxModule
import modules/module
import math
import strutils
import print
# import kissfft/kissfft
import fourierTransform
import resampling

proc update(moduleList: array[256, SynthModule]): void =
    for m in moduleList:
        if(m == nil): continue
        m.update = true
        if(m of BoxModule):
            echo "Updating Box"
            update((m.BoxModule).moduleList)
proc synthesize*(): void =

    # for m in synthContext.moduleList:
    #     if(m == nil): continue
    #     m.update = true

    update(synthContext.moduleList)
    # print(synthContext)

    let outModule = synthContext.moduleList[synthContext.outputIndex].OutputModule
    echo outModule.inputs[0].pinIndex

    let overSampleValue = 1.0/synthContext.oversample.float64

    for i in 0..<synthContext.waveDims.x:
        var sum = 0.0
        var j = 0.0
        while(j < 1):
            sum += outModule.synthesize((i.float64 + j) * PI * 2 / synthContext.waveDims.x.float64, outModule.inputs[0].pinIndex, synthContext.moduleList) * overSampleValue
            j += overSampleValue
        outputFloat[i] = sum

    # fourierTransform(outputFloat.addr, synthContext.waveDims.x)

    for i in 0..<synthContext.waveDims.x:
        var value = min(max(outputFloat[i], -1.0), 1.0) + 1

        outputInt[i] = round(value * (synthContext.waveDims.y.float64 / 2.0)).int32

proc synthesize2*(): void =
    update(synthContext.moduleList)
    # print(synthContext)

    let outModule = synthContext.moduleList[synthContext.outputIndex].OutputModule
    echo outModule.inputs[0].pinIndex

    let overSampleValue = 1.0/synthContext.oversample.float64

    for i in 0..<(4096 * 8):
        var sum = 0.0
        sum += outModule.synthesize((i.float64) * PI * 2 / (4096 * 8), outModule.inputs[0].pinIndex, synthContext.moduleList)
        outputFloat[i] = sum

    # fourierTransform(outputFloat.addr, synthContext.waveDims.x)

    resample()

proc generateWaveStr*(hex: bool = false): string =
    var str = ""
    for i in 0..<synthContext.waveDims.x:
        if(hex):
            var num = $(outputInt[i]).toHex().strip(true, chars = {'0'})
            if(num == ""): num = "0"
            str &= num & " "
        else:
            str &= $outputInt[i] & " "

    return str & ";"

proc generateSeqStr*(hex: bool = false): string =
    let macroBackup = synthContext.macroFrame
    var outStr = ""
    for mac in 0..<synthContext.macroLen:
        synthContext.macroFrame = mac
        synthesize()
        outStr &= generateWaveStr(hex) & "\n"
    synthContext.macroFrame = macroBackup
    synthesize()
    return outStr