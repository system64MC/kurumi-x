import ../../common/globals
import flatty
import synth
import ../../common/utils
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
    when not defined(emscripten):
        var obj: SynthSerializeObject
        obj.waveDims = synthContext.synthInfos.waveDims
        obj.oversample = synthContext.synthInfos.oversample
        obj.outputIndex = synthContext.outputIndex
        obj.macroLen = synthContext.synthInfos.macroLen
        obj.macroFrame = synthContext.synthInfos.macroFrame

        for n in 0..<synthContext.moduleList.len:
            let m = synthContext.moduleList[n]
            if(m == nil):
                obj.moduleList[n] = ModuleSerializationObject(mType: NULL, data: "")
                continue
            obj.moduleList[n] = m.serialize()

        let str = "VAMPIRE " & compress(toFlatty(obj))
        writeFile("backup.bak", str)
    else:
        return

proc unserializeModule(mData: ModuleSerializationObject): SynthModule =
    var module: SynthModule
    case mData.mType:
        of ABSOLUTER:
            module = mData.data.fromFlatty(AbsoluterModule)
        of AMPLIFIER:
            module = mData.data.fromFlatty(AmplifierModule)
        of AVERAGE:
            module = mData.data.fromFlatty(AverageModule)
        of BQ_FILTER:
            module = mData.data.fromFlatty(BqFilterModule)
        of CH_FILTER:
            module = mData.data.fromFlatty(ChebyshevFilterModule)
        of CHORD:
            module = mData.data.fromFlatty(ChordModule)
        of CLIPPER:
            module = mData.data.fromFlatty(ClipperModule)
        of DC_OFFSET:
            module = mData.data.fromFlatty(DcOffsetModule)
        of DOWNSAMPLER:
            module = mData.data.fromFlatty(DownsamplerModule)
        of DUAL_WAVE:
            module = mData.data.fromFlatty(DualWaveModule)
        of EXPONENT:
            module = mData.data.fromFlatty(ExpModule)
        of EXP_PLUS:
            module = mData.data.fromFlatty(ExpPlusModule)
        of FEEDBACK:
            module = mData.data.fromFlatty(FeedbackModule)
        of FM:
            module = mData.data.fromFlatty(FmodModule)
        of FM_PRO:
            module = mData.data.fromFlatty(FmProModule)
        of INVERTER:
            module = mData.data.fromFlatty(InverterModule)
        of LFO:
            module = mData.data.fromFlatty(LfoModule)
        of MIXER:
            module = mData.data.fromFlatty(MixerModule)
        of MORPHER:
            module = mData.data.fromFlatty(MorphModule)
        of MULT:
            module = mData.data.fromFlatty(MultModule)
        of NOISE:
            module = mData.data.fromFlatty(NoiseOscillatorModule)
        of NORMALIZER:
            module = mData.data.fromFlatty(NormalizerModule)
        of SINE_OSC:
            module = mData.data.fromFlatty(SineOscillatorModule)
        of TRI_OSC:
            module = mData.data.fromFlatty(TriangleOscillatorModule)
        of SAW_OSC:
            module = mData.data.fromFlatty(SawOscillatorModule)
        of PULSE_OSC:
            module = mData.data.fromFlatty(SquareOscillatorModule)
        of WAVE_OSC:
            module = mData.data.fromFlatty(WavetableOscillatorModule)
        of OUTPUT:
            module = mData.data.fromFlatty(OutputModule)
        of PHASE_DIST:
            module = mData.data.fromFlatty(PdModule)
        of PHASE:
            module = mData.data.fromFlatty(PhaseModule)
        of QUANTIZER:
            module = mData.data.fromFlatty(QuantizerModule)
        of RECTIFIER:
            module = mData.data.fromFlatty(RectifierModule)
        of SOFT_CLIP:
            module = mData.data.fromFlatty(SoftClipModule)
        of SPLITTER:
            module = mData.data.fromFlatty(SplitterModule)
        of SYNC:
            module = mData.data.fromFlatty(SyncModule)
        of UNISON:
            module = mData.data.fromFlatty(UnisonModule)
        of WAVE_FOLDER:
            module = mData.data.fromFlatty(WaveFolderModule)
        of WAVE_FOLD:
            module = mData.data.fromFlatty(WaveFoldModule)
        of MIRROR:
            module = mData.data.fromFlatty(WaveMirrorModule)
        of QUAD_WAVE_ASM:
            module = mData.data.fromFlatty(QuadWaveAssemblerModule)
        of CALCULATOR:
            module = mData.data.fromFlatty(CalculatorModule)
        of FAST_FEEDBACK:
            module = mData.data.fromFlatty(FastFeedbackModule)
        of FAST_BQ_FILTER:
            module = mData.data.fromFlatty(FastBqFilterModule)
        of BOX:
            let sData = mData.data.fromFlatty(BoxModuleSerialize)
            var moduleBox = BoxModule()
            var modList: array[16 * 16, SynthModule]
            for i in 0..<sData.data.len():
                modList[i] = sData.data[i].unserializeModule()
            moduleBox.inputIndex = sData.inputIndex
            moduleBox.outputIndex = sData.outputIndex
            moduleBox.inputs = sData.inputs
            moduleBox.outputs = sData.outputs
            moduleBox.moduleList = modList
            moduleBox.name = sData.name
            return moduleBox
        of AVG_FILTER:
            module = mData.data.fromFlatty(AvgFilterModule)
        of WAVE_SHAPER:
            module = mData.data.fromFlatty(WaveShaperModule)
        of AMP_MASK:
            module = mData.data.fromFlatty(AmpMaskModule)
        of PHASE_MASK:
            module = mData.data.fromFlatty(PhaseMaskModule)
        of OR:
            module = mData.data.fromFlatty(OrModule)
        of XOR:
            module = mData.data.fromFlatty(XorModule)
        of AND:
            module = mData.data.fromFlatty(AndModule)
        else:
            module = nil
    return module       

var moduleClipboard*: ModuleSerializationObject

proc unserializeModules(synth: Synth, data: SynthSerializeObject) =
    for i in 0..<data.moduleList.len:
        let mData = data.moduleList[i]
        synth.moduleList[i] = mData.unserializeModule()

proc unserializeFromClipboard*(): SynthModule =
    return moduleClipboard.unserializeModule()

proc loadState*() =
    try:
        let str = readFile("backup.bak")
        if(str.substr(0, "VAMPIRE ".len - 1) != "VAMPIRE "): return
        let data = str.substr("VAMPIRE ".len).uncompress().fromFlatty(SynthSerializeObject)
        # let data = str.fromFlatty(SynthSerializeObject)
        synthContext.synthInfos.waveDims = data.waveDims
        synthContext.synthInfos.oversample = data.oversample
        synthContext.outputIndex = data.outputIndex
        synthContext.synthInfos.macroLen = data.macroLen
        synthContext.synthInfos.macroFrame = data.macroFrame
        synthContext.unserializeModules(data)
        synthContext.synthesize()

    except IOError:
        echo "error"
        return

proc saveStateHistory*(synth: Synth): string =
    var obj: SynthSerializeObject
    obj.waveDims = synthContext.synthInfos.waveDims
    obj.oversample = synthContext.synthInfos.oversample
    obj.outputIndex = synthContext.outputIndex
    obj.macroLen = synthContext.synthInfos.macroLen
    obj.macroFrame = synthContext.synthInfos.macroFrame

    for n in 0..<synth.moduleList.len:
        let m = synth.moduleList[n]
        if(m == nil):
            obj.moduleList[n] = ModuleSerializationObject(mType: NULL, data: "")
            continue
        obj.moduleList[n] = m.serialize()

    let str = "VAMPIRE " & compress(toFlatty(obj))
    return str

proc loadStateHistory*(data: string): Synth =
    let str = data
    if(str.substr(0, "VAMPIRE ".len - 1) != "VAMPIRE "): return
    let data = str.substr("VAMPIRE ".len).uncompress().fromFlatty(SynthSerializeObject)
    var synth = (Synth)()
    # let data = str.fromFlatty(SynthSerializeObject)
    synth.synthInfos.waveDims = data.waveDims
    synth.synthInfos.oversample = data.oversample
    synth.outputIndex = data.outputIndex
    synth.synthInfos.macroLen = data.macroLen
    synth.synthInfos.macroFrame = data.macroFrame
    synth.unserializeModules(data)
    synth.synthesize()
    return synth