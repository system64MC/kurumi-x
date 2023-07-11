import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]
import ../synthesizer/synth
import ../synthesizer/linkManagement
import ../synthesizer/synthesizeWave
# import ../synthesizer/modules/[
#     oscillatorModule, 
#     fmModule, 
#     mixerModule, 
#     amplifierModule, 
#     absoluterModule, 
#     rectifierModule, 
#     clipperModule, 
#     inverterModule, 
#     pdModule, 
#     syncModule,
#     morphModule,
#     expModule,
#     multModule,
#     dualWaveModule,
#     averageModule,
#     fmProModule,
#     phaseModule,
#     waveFoldModule,
#     waveMirrorModule,
#     dcOffsetModule,
#     chordModule,
#     feedbackModule,
#     downsamplerModule,
#     quantizerModule,
#     outputModule,
#     lfoModule,
#     softClipModule,
#     waveFolderModule,
#     splitterModule,
#     normalizerModule,
#     bqFilterModule,
#     unisonModule,
#     noiseModule,
#     module
# ]
import ../synthesizer/modules
import ../synthesizer/globals
import ../synthesizer/serialization
import history

const modEntries = [
    "Output".cstring,
    "Oscillator",
    "Phase Modulation",
]

type
    ActionType = enum
        OUTPUT,
        OSCILLATOR,
        PHASE_MODULATION

proc executeContextClick(index: int, actionId: int): void =
    case actionId.ActionType
    of OUTPUT:
        echo "OUTPUT " & $index
    of OSCILLATOR:
        echo "OSCILLATOR " & $index
    of PHASE_MODULATION:
        echo "FM " & $index
        
    
    return

proc copyPasteOps*(cellIndex: int, moduleList: var array[256, SynthModule], outIndex: uint16, boxModule: BoxModule = nil): void {.inline.} =
    if(igGetIO().keyCtrl and igGetIO().keyShift and igIsKeyPressed(igGetKeyIndex(ImGuiKey.C))):
        let module = moduleList[cellIndex]
        if not(module of OutputModule):
            if(module != nil): moduleClipboard = module.serialize()
        return
    if(igGetIO().keyCtrl and igGetIO().keyShift and igIsKeyPressed(igGetKeyIndex(ImGuiKey.V))):
        let module = synthContext.moduleList[cellIndex]
        if not(module of OutputModule):
            if(module != nil):
                module.breakAllLinks(moduleList)
                deleteModule(cellIndex, moduleList)
            moduleList[cellIndex] = unserializeFromClipboard()
            # synthContext.moduleList[index].breakAllLinks(synthContext.moduleList)
            moduleList[cellIndex].resetLinks()
            synthesize()
            registerHistoryEvent("Paste Module")
        return
    if(igGetIO().keyCtrl and igGetIO().keyShift and igIsKeyPressed(igGetKeyIndex(ImGuiKey.X))):
        let module = moduleList[cellIndex]
        if not(module of OutputModule):
            if(module != nil):
                module.breakAllLinks(synthContext.moduleList)
                moduleClipboard = module.serialize()
                deleteModule(cellIndex, moduleList)
                synthesize()
                registerHistoryEvent("Cut Module")
        return
    if(igGetIO().keyAlt and igIsKeyPressed(68)):
        let module = moduleList[cellIndex]
        if not(module of OutputModule):
            if(module != nil):
                deleteModule(cellIndex, moduleList)
                synthesize()
                registerHistoryEvent("Delete module")
        return
    if(igGetIO().keyAlt and igIsKeyPressed(igGetKeyIndex(ImGuiKey.V))):
        let module = moduleList[cellIndex]
        module.breakAllLinks(moduleList)
        moduleList[outIndex].breakAllLinks(moduleList)
        moduleList[outIndex] = nil
        moduleList[cellIndex] = constructOutputModule()
        if(boxModule == nil):
            synthContext.outputIndex = cellIndex.uint16
        else:
            boxModule.outputIndex = cellIndex.uint16
        synthesize()
        registerHistoryEvent("Moved Output")
        return

proc drawContextMenu(cellIndex: int, moduleList: var array[256, SynthModule], outIndex: uint16, boxModule: BoxModule = nil): void {.inline.} =
    var oldModule = moduleList[cellIndex]


    if(igMenuItem("Set output here")):
        oldModule.breakAllLinks(moduleList)
        moduleList[outIndex].breakAllLinks(moduleList)
        moduleList[outIndex] = nil
        moduleList[cellIndex] = constructOutputModule()
        if(boxModule == nil):
            synthContext.outputIndex = cellIndex.uint16
        else:
            boxModule.outputIndex = cellIndex.uint16
        synthesize()
        registerHistoryEvent("Moved Output")

    if (moduleList[cellIndex] of OutputModule): return

    igSeparator()

    if(igMenuItem("Copy")):
        if(oldModule != nil): moduleClipboard = oldModule.serialize()

    if(igMenuItem("Cut")):
        if(oldModule != nil):
            oldModule.breakAllLinks(moduleList)
            moduleClipboard = oldModule.serialize()
            deleteModule(cellIndex, moduleList) 
            synthesize()
            registerHistoryEvent("Cut Module")
    
    if(igMenuItem("Paste")):
        if(oldModule != nil):
            oldModule.breakAllLinks(moduleList)
            deleteModule(cellIndex, moduleList)
        moduleList[cellIndex] = unserializeFromClipboard()
        # moduleList[cellIndex].breakAllLinks(moduleList)
        moduleList[cellIndex].resetLinks()
        synthesize()
        registerHistoryEvent("Paste Module")

    igSeparator()

    if(igBeginMenu("Oscillators")):
        if(igMenuItem("Sine Oscillator")):
            moduleList[cellIndex] = constructSineOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Sine OSC. Module")

        if(igMenuItem("Triangle Oscillator")):
            moduleList[cellIndex] = constructTriangleOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Triangle OSC. Module")

        if(igMenuItem("Saw Oscillator")):
            moduleList[cellIndex] = constructSawOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Saw OSC. Module")

        if(igMenuItem("Pulse Oscillator")):
            moduleList[cellIndex] = constructSquareOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Pulse OSC. Module")

        if(igMenuItem("Wavetable Oscillator")):
            moduleList[cellIndex] = constructWavetableOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Wavetable OSC. Module")

        if(igMenuItem("Noise Oscillator")):
            moduleList[cellIndex] = constructNoiseOscillatorModule()
            synthesize()
            registerHistoryEvent("Created Noise OSC. Module")
        igEndMenu()

    if(igMenuItem("FM")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFmodModule()
        synthesize()
        registerHistoryEvent("Created FM Module")

    if(igMenuItem("FM Pro")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFmProModule()
        synthesize()
        registerHistoryEvent("Created FM Pro Module")

    if(igMenuItem("Mixer")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructMixerModule()
        synthesize()
        registerHistoryEvent("Created Mixer Module")

    if(igMenuItem("Average")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructAverageModule()
        synthesize()
        registerHistoryEvent("Created Average Module")

    if(igMenuItem("Amplifier")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructAmplifierModule()
        synthesize()
        registerHistoryEvent("Created Amplifier Module")

    if(igMenuItem("Rectifier")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructRectifierModule()
        synthesize()
        registerHistoryEvent("Created Rectifier Module")

    if(igMenuItem("Absoluter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructAbsoluterModule()
        synthesize()
        registerHistoryEvent("Created Absoluter Module")

    if(igMenuItem("Clipper")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructClipperModule()
        synthesize()
        registerHistoryEvent("Created Clipper Module")
    
    if(igMenuItem("Inverter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructInverterModule()
        synthesize()
        registerHistoryEvent("Created Inverter Module")

    if(igMenuItem("Phase dist.")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructPdModule()
        synthesize()
        registerHistoryEvent("Created Phase Distortion Module")
    
    if(igMenuItem("Sync")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructSyncModule()
        synthesize()
        registerHistoryEvent("Created Sync Module")

    if(igMenuItem("Morpher")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructMorphModule()
        synthesize()
        registerHistoryEvent("Created Morpher Module")

    if(igMenuItem("Exponenter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructExpModule()
        synthesize()
        registerHistoryEvent("Created Exponenter Module")

    # if(igMenuItem("Overflower")):
    #     oldModule.breakAllLinks(moduleList)
    #     moduleList[cellIndex] = constructOverflowModule()
    #     synthesize()

    if(igMenuItem("Multiplier")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructMultModule()
        synthesize()
        registerHistoryEvent("Created Multiplier Module")

    if(igMenuItem("DualWave")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructDualWaveModule()
        synthesize()
        registerHistoryEvent("Created DualWave Module")

    if(igMenuItem("Phase")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructPhaseModule()
        synthesize()
        registerHistoryEvent("Created Phase Module")

    if(igMenuItem("Wave Folding")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructWaveFoldModule()
        synthesize()
        registerHistoryEvent("Created Wave Folding Module")
    
    if(igMenuItem("Wave Mirroring")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructWaveMirrorModule()
        synthesize()
        registerHistoryEvent("Created Wave Mirroring Module")

    if(igMenuItem("DC Offset")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructDcOffsetModule()
        synthesize()
        registerHistoryEvent("Created DC Offset Module")

    if(igMenuItem("Chord")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructChordModule()
        synthesize()
        registerHistoryEvent("Created Chord Module")

    if(igMenuItem("FM Feedback")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFeedbackModule()
        synthesize()
        registerHistoryEvent("Created FM Feedback Module")

    if(igMenuItem("Fast FM Feedback")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFastFeedbackModule()
        synthesize()
        registerHistoryEvent("Created Fast FM FB Module")

    if(igMenuItem("Downsampler")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructDownsamplerModule()
        synthesize()
        registerHistoryEvent("Created DOwnsample Module")

    if(igMenuItem("Quantizer")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructQuantizerModule()
        synthesize()
        registerHistoryEvent("Created Quantizer Module")

    if(igMenuItem("LFO")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructLfoModule()
        synthesize()
        registerHistoryEvent("Created LFO Module")

    if(igMenuItem("Soft Clip")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructSoftClipModule()
        synthesize()
        registerHistoryEvent("Created Soft Clip Module")

    if(igMenuItem("Wave Folder")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructWaveFolderModule()
        synthesize()
        registerHistoryEvent("Created Wave Folder Module")

    if(igMenuItem("Splitter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructSplitterModule()
        synthesize()
        registerHistoryEvent("Created Splitter Module")

    if(igMenuItem("Normalizer")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructNormalizerModule()
        synthesize()
        registerHistoryEvent("Created Normalizer Module")

    if(igMenuItem("Biquad Filter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructBqFilterModule()
        synthesize()
        registerHistoryEvent("Created Biquad Filter Module")

    if(igMenuItem("Fast Biquad Filter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFastBqFilterModule()
        synthesize()
        registerHistoryEvent("Created Fast BQ. Module")

    if(igMenuItem("Chebyshev Filter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructChebyshevFilterModule()
        synthesize()
        registerHistoryEvent("Created Chebyshev Filter Module")

    if(igMenuItem("Fast Chebyshev Filter")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructFastChebyshevFilterModule()
        synthesize()
        registerHistoryEvent("Created Fast CH. Module")
    
    if(igMenuItem("Unison")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructUnisonModule()
        synthesize()
        registerHistoryEvent("Created Unison Module")

    if(igMenuItem("Quad Wave Assembler")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructQuadWaveAssemblerModule()
        synthesize()
        registerHistoryEvent("Created Quad Wave ASM Module")

    if(igMenuItem("Calculator")):
        oldModule.breakAllLinks(moduleList)
        moduleList[cellIndex] = constructCalculatorModule()
        synthesize()
        registerHistoryEvent("Created Calculator Module")
    
    # CAUTION : This if statement is a temporary solution while I try to fix the "Abnormal Termination" crash.
    if(boxModule == nil):
        if(igMenuItem("Box")):
            oldModule.breakAllLinks(moduleList)
            moduleList[cellIndex] = constructBoxModule()
            synthesize()
            registerHistoryEvent("Created Box Module")

proc drawModuleCreationContextMenu*(cellIndex: int, moduleList: var array[256, SynthModule], outIndex: uint16): void {.inline.} =
    if(igBeginPopupContextItem(("moduleContext" & $cellIndex).cstring)):
        drawContextMenu(cellIndex, moduleList, outIndex)
        igEndPopup()

proc drawModuleCreationContextMenuBox*(cellIndex: int, moduleList: var array[256, SynthModule], outIndex: uint16, moduleBox: BoxModule): void {.inline.} =
    if(igBeginPopupContextItem(("moduleContextBox" & $cellIndex).cstring)):
        drawContextMenu(cellIndex, moduleList, outIndex, moduleBox)
        igEndPopup()
    
        
    