import ../../common/globals
import ../../common/utils
import synth
import ../synthesizer/modules/[fmModule, module, mixerModule, oscillatorModule]

proc breakLinksInput*(module: SynthModule, pin: int, moduleList: var array[256, SynthModule]): void =
    if(module.inputs[pin].moduleIndex < 0 or module.inputs[pin].pinIndex < 0): return
    var moduleIn = moduleList[module.inputs[pin].moduleIndex]
    moduleIn.outputs[module.inputs[pin].pinIndex].pinIndex = -1
    moduleIn.outputs[module.inputs[pin].pinIndex].moduleIndex = -1
    module.inputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

proc breakLinksOutput*(module: SynthModule, pin: int, moduleList: var array[256, SynthModule]): void =
    if(module.outputs[pin].moduleIndex < 0 or module.outputs[pin].pinIndex < 0): return
    var moduleOut = moduleList[module.outputs[pin].moduleIndex]
    moduleOut.inputs[module.outputs[pin].pinIndex].pinIndex = -1
    moduleOut.inputs[module.outputs[pin].pinIndex].moduleIndex = -1
    module.outputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

proc breakAllLinks*(module: SynthModule, moduleList: var array[256, SynthModule]): void =
    if(module == nil): return
    for pin in 0..<module.outputs.len:
        breakLinksOutput(module, pin, moduleList)

    for pin in 0..<module.inputs.len:
        breakLinksInput(module, pin, moduleList)

proc resetLinks*(module: SynthModule): void =
    if(module == nil): return
    for pin in 0..<module.outputs.len:
        module.outputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

    for pin in 0..<module.inputs.len:
        module.inputs[pin] = Link(moduleIndex: -1, pinIndex: -1)

proc makeLink*(module: SynthModule, index: int, pin: int, moduleList: var array[256, SynthModule]): void =
    module.inputs[pin] = selectedLink
    var inputModule = moduleList[selectedLink.moduleIndex]
    inputModule.outputs[selectedLink.pinIndex].moduleIndex = index.int16
    inputModule.outputs[selectedLink.pinIndex].pinIndex = pin.int16
    selectedLink.moduleIndex = -1
    selectedLink.pinIndex = -1
    return

proc deleteModule*(moduleIndex: int, moduleList: var array[256, SynthModule]): void =
    var module = moduleList[moduleIndex]
    for i in 0..<module.inputs.len:
        module.breakLinksInput(i, moduleList)
    
    for i in 0..<module.outputs.len:
        module.breakLinksOutput(i, moduleList)

    moduleList[moduleIndex] = nil