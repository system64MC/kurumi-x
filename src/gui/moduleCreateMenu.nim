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

proc drawContextMenu(cellIndex: int): void {.inline.} =
    var oldModule = synthContext.moduleList[cellIndex]


    if(igMenuItem("Set output here")):
        oldModule.breakAllLinks()
        synthContext.moduleList[synthContext.outputIndex].breakAllLinks()
        synthContext.moduleList[synthContext.outputIndex] = nil
        synthContext.moduleList[cellIndex] = constructOutputModule()
        synthContext.outputIndex = cellIndex.uint16
        synthesize()

    if (synthContext.moduleList[cellIndex] of OutputModule): return

    igSeparator()

    if(igMenuItem("Copy")):
        if(oldModule != nil): moduleClipboard = oldModule.serialize()

    if(igMenuItem("Cut")):
        if(oldModule != nil):
            oldModule.breakAllLinks()
            moduleClipboard = oldModule.serialize()
            deleteModule(cellIndex) 
            synthesize()
    
    if(igMenuItem("Paste")):
        if(oldModule != nil):
            oldModule.breakAllLinks()
            deleteModule(cellIndex)
        synthContext.moduleList[cellIndex] = unserializeFromClipboard()
        synthContext.moduleList[cellIndex].breakAllLinks()
        synthesize()

    igSeparator()

    if(igBeginMenu("Oscillators")):
        if(igMenuItem("Sine Oscillator")):
            synthContext.moduleList[cellIndex] = constructSineOscillatorModule()
            synthesize()

        if(igMenuItem("Triangle Oscillator")):
            synthContext.moduleList[cellIndex] = constructTriangleOscillatorModule()
            synthesize()

        if(igMenuItem("Saw Oscillator")):
            synthContext.moduleList[cellIndex] = constructSawOscillatorModule()
            synthesize()

        if(igMenuItem("Pulse Oscillator")):
            synthContext.moduleList[cellIndex] = constructSquareOscillatorModule()
            synthesize()

        if(igMenuItem("Wavetable Oscillator")):
            synthContext.moduleList[cellIndex] = constructWavetableOscillatorModule()
            synthesize()

        if(igMenuItem("Noise Oscillator")):
            synthContext.moduleList[cellIndex] = constructNoiseOscillatorModule()
            synthesize()
        igEndMenu()

    if(igMenuItem("FM")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructFmodModule()
        synthesize()

    if(igMenuItem("FM Pro")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructFmProModule()
        synthesize()

    if(igMenuItem("Mixer")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructMixerModule()
        synthesize()

    if(igMenuItem("Average")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructAverageModule()
        synthesize()

    if(igMenuItem("Amplifier")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructAmplifierModule()
        synthesize()

    if(igMenuItem("Rectifier")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructRectifierModule()
        synthesize()

    if(igMenuItem("Absoluter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructAbsoluterModule()
        synthesize()

    if(igMenuItem("Clipper")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructClipperModule()
        synthesize()
    
    if(igMenuItem("Inverter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructInverterModule()
        synthesize()

    if(igMenuItem("Phase dist.")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructPdModule()
        synthesize()
    
    if(igMenuItem("Sync")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructSyncModule()
        synthesize()

    if(igMenuItem("Morpher")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructMorphModule()
        synthesize()

    if(igMenuItem("Exponenter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructExpModule()
        synthesize()

    # if(igMenuItem("Overflower")):
    #     oldModule.breakAllLinks()
    #     synthContext.moduleList[cellIndex] = constructOverflowModule()
    #     synthesize()

    if(igMenuItem("Multiplier")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructMultModule()
        synthesize()

    if(igMenuItem("DualWave")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructDualWaveModule()
        synthesize()

    if(igMenuItem("Phase")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructPhaseModule()
        synthesize()

    if(igMenuItem("Wave Folding")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructWaveFoldModule()
        synthesize()
    
    if(igMenuItem("Wave Mirroring")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructWaveMirrorModule()
        synthesize()

    if(igMenuItem("DC Offset")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructDcOffsetModule()
        synthesize()

    if(igMenuItem("Chord")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructChordModule()
        synthesize()

    if(igMenuItem("FM Feedback")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructFeedbackModule()
        synthesize()

    if(igMenuItem("Downsampler")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructDownsamplerModule()
        synthesize()

    if(igMenuItem("Quantizer")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructQuantizerModule()
        synthesize()

    if(igMenuItem("LFO")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructLfoModule()
        synthesize()

    if(igMenuItem("Soft Clip")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructSoftClipModule()
        synthesize()

    if(igMenuItem("Wave Folder")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructWaveFolderModule()
        synthesize()

    if(igMenuItem("Splitter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructSplitterModule()
        synthesize()

    if(igMenuItem("Normalizer")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructNormalizerModule()
        synthesize()

    if(igMenuItem("Biquad Filter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructBqFilterModule()
        synthesize()

    if(igMenuItem("Chebyshev Filter")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructChebyshevFilterModule()
        synthesize()
    
    if(igMenuItem("Unison")):
        oldModule.breakAllLinks()
        synthContext.moduleList[cellIndex] = constructUnisonModule()
        synthesize()

proc drawModuleCreationContextMenu*(cellIndex: int): void {.inline.} =
    if(igBeginPopupContextItem(("moduleContext" & $cellIndex).cstring)):
        drawContextMenu(cellIndex)
        igEndPopup()
    
        
    