import globals
import modules/outputModule
import math
import strutils
# import kissfft/kissfft
import fourierTransform

proc synthesize*(): void =

    for m in synthContext.moduleList:
        if(m == nil): continue
        m.update = true

    let outModule = synthContext.moduleList[synthContext.outputIndex].OutputModule
    echo outModule.inputs[0].pinIndex

    let overSampleValue = 1.0/synthContext.oversample.float64

    for i in 0..<synthContext.waveDims.x:
        var sum = 0.0
        var j = 0.0
        while(j < 1):
            sum += outModule.synthesize((i.float64 + j) * PI * 2 / synthContext.waveDims.x.float64, outModule.inputs[0].pinIndex) * overSampleValue
            j += overSampleValue
        outputFloat[i] = sum

    # fourierTransform(outputFloat.addr, synthContext.waveDims.x)

    for i in 0..<synthContext.waveDims.x:
        var value = min(max(outputFloat[i], -1.0), 1.0) + 1

        outputInt[i] = round(value * (synthContext.waveDims.y.float64 / 2.0)).int32

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