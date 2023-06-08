import globals
import utils/utils
import synth
import ../synthesizer/modules/[fmModule, module, mixerModule, oscillatorModule]

proc breakLinksInput*(module: SynthModule, pin: int): void =
    if(module.inputs[pin].moduleIndex < 0 or module.inputs[pin].pinIndex < 0): return
    var moduleIn = synthContext.moduleList[module.inputs[pin].moduleIndex]
    moduleIn.outputs[module.inputs[pin].pinIndex].pinIndex = -1
    moduleIn.outputs[module.inputs[pin].pinIndex].moduleIndex = -1
    module.inputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

proc breakLinksOutput*(module: SynthModule, pin: int): void =
    if(module.outputs[pin].moduleIndex < 0 or module.outputs[pin].pinIndex < 0): return
    var moduleOut = synthContext.moduleList[module.outputs[pin].moduleIndex]
    moduleOut.inputs[module.outputs[pin].pinIndex].pinIndex = -1
    moduleOut.inputs[module.outputs[pin].pinIndex].moduleIndex = -1
    module.outputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

proc breakAllLinks*(module: SynthModule): void =
    if(module == nil): return
    for pin in 0..<module.outputs.len:
        breakLinksOutput(module, pin)

    for pin in 0..<module.inputs.len:
        breakLinksInput(module, pin)

proc makeLink*(module: SynthModule, index: int, pin: int): void =
    module.inputs[pin] = selectedLink
    var inputModule = synthContext.moduleList[selectedLink.moduleIndex]
    inputModule.outputs[selectedLink.pinIndex].moduleIndex = index.int16
    inputModule.outputs[selectedLink.pinIndex].pinIndex = pin.int16
    selectedLink.moduleIndex = -1
    selectedLink.pinIndex = -1
    return

proc deleteModule*(moduleIndex: int): void =
    var module = synthContext.moduleList[moduleIndex]
    for i in 0..<module.inputs.len:
        module.breakLinksInput(i)
    
    for i in 0..<module.outputs.len:
        module.breakLinksOutput(i)

    synthContext.moduleList[moduleIndex] = nil