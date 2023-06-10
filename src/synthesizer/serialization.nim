import globals
import flatty
import synth
import utils/utils
import supersnappy
# import modules/[
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
#     module,
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
#     noiseModule
# ]
import modules
import serializationObject
import synthesizeWave



type
    SynthSerializeObject = object
        moduleList*: array[GRID_SIZE_X * GRID_SIZE_Y, ModuleSerializationObject]
        waveDims*: VecI32 = VecI32(x: 32, y: 15)
        oversample*: int32
        outputIndex*: uint16
        macroLen*: int32
        macroFrame*: int32

proc saveState*() =
    var obj: SynthSerializeObject
    obj.waveDims = synthContext.waveDims
    obj.oversample = synthContext.oversample
    obj.outputIndex = synthContext.outputIndex
    obj.macroLen = synthContext.macroLen
    obj.macroFrame = synthContext.macroFrame

    for n in 0..<synthContext.moduleList.len:
        let m = synthContext.moduleList[n]
        if(m == nil):
            obj.moduleList[n] = ModuleSerializationObject(mType: NULL, data: "")
            continue
        obj.moduleList[n] = m.serialize()

    let str = "VAMPIRE " & compress(toFlatty(obj))
    writeFile("backup.bak", str)

proc unserializeModules(data: SynthSerializeObject) =
    for i in 0..<data.moduleList.len:
        let mData = data.moduleList[i]
        case mData.mType:
        of ABSOLUTER:
            synthContext.moduleList[i] = mData.data.fromFlatty(AbsoluterModule)
        of AMPLIFIER:
            synthContext.moduleList[i] = mData.data.fromFlatty(AmplifierModule)
        of AVERAGE:
            synthContext.moduleList[i] = mData.data.fromFlatty(AverageModule)
        of BQ_FILTER:
            synthContext.moduleList[i] = mData.data.fromFlatty(BqFilterModule)
        of CH_FILTER:
            synthContext.moduleList[i] = mData.data.fromFlatty(ChebyshevFilterModule)
        of CHORD:
            synthContext.moduleList[i] = mData.data.fromFlatty(ChordModule)
        of CLIPPER:
            synthContext.moduleList[i] = mData.data.fromFlatty(ClipperModule)
        of DC_OFFSET:
            synthContext.moduleList[i] = mData.data.fromFlatty(DcOffsetModule)
        of DOWNSAMPLER:
            synthContext.moduleList[i] = mData.data.fromFlatty(DownsamplerModule)
        of DUAL_WAVE:
            synthContext.moduleList[i] = mData.data.fromFlatty(DualWaveModule)
        of EXPONENT:
            synthContext.moduleList[i] = mData.data.fromFlatty(ExpModule)
        of FEEDBACK:
            synthContext.moduleList[i] = mData.data.fromFlatty(FeedbackModule)
        of FM:
            synthContext.moduleList[i] = mData.data.fromFlatty(FmodModule)
        of FM_PRO:
            synthContext.moduleList[i] = mData.data.fromFlatty(FmProModule)
        of INVERTER:
            synthContext.moduleList[i] = mData.data.fromFlatty(InverterModule)
        of LFO:
            synthContext.moduleList[i] = mData.data.fromFlatty(LfoModule)
        of MIXER:
            synthContext.moduleList[i] = mData.data.fromFlatty(MixerModule)
        of MORPHER:
            synthContext.moduleList[i] = mData.data.fromFlatty(MorphModule)
        of MULT:
            synthContext.moduleList[i] = mData.data.fromFlatty(MultModule)
        of NOISE:
            synthContext.moduleList[i] = mData.data.fromFlatty(NoiseOscillatorModule)
        of NORMALIZER:
            synthContext.moduleList[i] = mData.data.fromFlatty(NormalizerModule)
        of SINE_OSC:
            synthContext.moduleList[i] = mData.data.fromFlatty(SineOscillatorModule)
        of TRI_OSC:
            synthContext.moduleList[i] = mData.data.fromFlatty(TriangleOscillatorModule)
        of SAW_OSC:
            synthContext.moduleList[i] = mData.data.fromFlatty(SawOscillatorModule)
        of PULSE_OSC:
            synthContext.moduleList[i] = mData.data.fromFlatty(SquareOscillatorModule)
        of WAVE_OSC:
            synthContext.moduleList[i] = mData.data.fromFlatty(WavetableOscillatorModule)
        of OUTPUT:
            synthContext.moduleList[i] = mData.data.fromFlatty(OutputModule)
        of PHASE_DIST:
            synthContext.moduleList[i] = mData.data.fromFlatty(PdModule)
        of PHASE:
            synthContext.moduleList[i] = mData.data.fromFlatty(PhaseModule)
        of QUANTIZER:
            synthContext.moduleList[i] = mData.data.fromFlatty(QuantizerModule)
        of RECTIFIER:
            synthContext.moduleList[i] = mData.data.fromFlatty(RectifierModule)
        of SOFT_CLIP:
            synthContext.moduleList[i] = mData.data.fromFlatty(SoftClipModule)
        of SPLITTER:
            synthContext.moduleList[i] = mData.data.fromFlatty(SplitterModule)
        of SYNC:
            synthContext.moduleList[i] = mData.data.fromFlatty(SyncModule)
        of UNISON:
            synthContext.moduleList[i] = mData.data.fromFlatty(UnisonModule)
        of WAVE_FOLDER:
            synthContext.moduleList[i] = mData.data.fromFlatty(WaveFolderModule)
        of WAVE_FOLD:
            synthContext.moduleList[i] = mData.data.fromFlatty(WaveFoldModule)
        of MIRROR:
            synthContext.moduleList[i] = mData.data.fromFlatty(WaveMirrorModule)
        else:
            synthContext.moduleList[i] = nil
            
        

proc loadState*() =
    try:
        let str = readFile("backup.bak")
        if(str.substr(0, "VAMPIRE ".len - 1) != "VAMPIRE "): return
        let data = str.substr("VAMPIRE ".len).uncompress().fromFlatty(SynthSerializeObject)
        # let data = str.fromFlatty(SynthSerializeObject)
        synthContext.waveDims = data.waveDims
        synthContext.oversample = data.oversample
        synthContext.outputIndex = data.outputIndex
        synthContext.macroLen = data.macroLen
        synthContext.macroFrame = data.macroFrame
        data.unserializeModules()
        synthesize()

    except IOError:
        echo "error"
        return

var moduleClipboard*: ModuleSerializationObject

proc unserializeFromClipboard*(): SynthModule =
    case moduleClipboard.mType:
        of ABSOLUTER:
            return moduleClipboard.data.fromFlatty(AbsoluterModule)
        of AMPLIFIER:
            return moduleClipboard.data.fromFlatty(AmplifierModule)
        of AVERAGE:
            return moduleClipboard.data.fromFlatty(AverageModule)
        of BQ_FILTER:
            return moduleClipboard.data.fromFlatty(BqFilterModule)
        of CHORD:
            return moduleClipboard.data.fromFlatty(ChordModule)
        of CLIPPER:
            return moduleClipboard.data.fromFlatty(ClipperModule)
        of DC_OFFSET:
            return moduleClipboard.data.fromFlatty(DcOffsetModule)
        of DOWNSAMPLER:
            return moduleClipboard.data.fromFlatty(DownsamplerModule)
        of DUAL_WAVE:
            return moduleClipboard.data.fromFlatty(DualWaveModule)
        of EXPONENT:
            return moduleClipboard.data.fromFlatty(ExpModule)
        of FEEDBACK:
            return moduleClipboard.data.fromFlatty(FeedbackModule)
        of FM:
            return moduleClipboard.data.fromFlatty(FmodModule)
        of FM_PRO:
            return moduleClipboard.data.fromFlatty(FmProModule)
        of INVERTER:
            return moduleClipboard.data.fromFlatty(InverterModule)
        of LFO:
            return moduleClipboard.data.fromFlatty(LfoModule)
        of MIXER:
            return moduleClipboard.data.fromFlatty(MixerModule)
        of MORPHER:
            return moduleClipboard.data.fromFlatty(MorphModule)
        of MULT:
            return moduleClipboard.data.fromFlatty(MultModule)
        of NOISE:
            return moduleClipboard.data.fromFlatty(NoiseOscillatorModule)
        of NORMALIZER:
            return moduleClipboard.data.fromFlatty(NormalizerModule)
        of SINE_OSC:
            return moduleClipboard.data.fromFlatty(SineOscillatorModule)
        of TRI_OSC:
            return moduleClipboard.data.fromFlatty(TriangleOscillatorModule)
        of SAW_OSC:
            return moduleClipboard.data.fromFlatty(SawOscillatorModule)
        of PULSE_OSC:
            return moduleClipboard.data.fromFlatty(SquareOscillatorModule)
        of WAVE_OSC:
            return moduleClipboard.data.fromFlatty(WavetableOscillatorModule)
        of OUTPUT:
            return moduleClipboard.data.fromFlatty(OutputModule)
        of PHASE_DIST:
            return moduleClipboard.data.fromFlatty(PdModule)
        of PHASE:
            return moduleClipboard.data.fromFlatty(PhaseModule)
        of QUANTIZER:
            return moduleClipboard.data.fromFlatty(QuantizerModule)
        of RECTIFIER:
            return moduleClipboard.data.fromFlatty(RectifierModule)
        of SOFT_CLIP:
            return moduleClipboard.data.fromFlatty(SoftClipModule)
        of SPLITTER:
            return moduleClipboard.data.fromFlatty(SplitterModule)
        of SYNC:
            return moduleClipboard.data.fromFlatty(SyncModule)
        of UNISON:
            return moduleClipboard.data.fromFlatty(UnisonModule)
        of WAVE_FOLDER:
            return moduleClipboard.data.fromFlatty(WaveFolderModule)
        of WAVE_FOLD:
            return moduleClipboard.data.fromFlatty(WaveFoldModule)
        of MIRROR:
            return moduleClipboard.data.fromFlatty(WaveMirrorModule)
        else:
            return