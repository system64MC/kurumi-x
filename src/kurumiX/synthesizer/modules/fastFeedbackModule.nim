# import module
# import ../globals
# import ../utils/utils
# import ../synthInfos
# import math

# type
#     FeedbackModule* = ref object of SynthModule
#         feedback*: float32
#         prev: float64
#         curr: float64
#         buffer: array[4096, float64]

# proc constructFeedbackModule*(): FeedbackModule =
#     var module = new FeedbackModule
#     module.inputs = @[
#         Link(moduleIndex: -1, pinIndex: -1),
#     ]
#     module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
#     return module

# proc moduloFix(a, b: float64): float64 =
#     return ((a mod b) + b) mod b
# method synthesize(module: FeedbackModule, x: float64): float64 =
#     if(module.inputs[0].moduleIndex < 0): return 0
#     let moduleA = moduleList[module.inputs[0].moduleIndex]

#     var x1 = 0.0
#     var res = 0.0
#     const delta = 1.0 / 4096.0
#     var phase = 0.0

#     if(module.update):
#         if(moduleA == nil):
#             while(x1 < 1):
#                 module.prev = 0
#                 module.buffer[(x1 / delta).int] = 0
#                 x1 += delta
#         else:
#             while(x1 < 1):
#                 phase += delta + (moduleA.synthesize(phase) - (module.prev.float64)) * module.feedback
#                 module.prev = res
#                 res = moduleA.synthesize(phase)
#                 module.buffer[(x1 / delta).int] = res
#                 x1 += delta
#         module.update = false

#     if(moduleA == nil):
#         return 0.0

#     module.prev = 0
#     module.curr = 0
#     return module.buffer[math.floor(moduloFix(x, 1)/delta).int]



import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
import math

type
    FastFeedbackModule* = ref object of SynthModule
        fbEnvelope*: Adsr = Adsr(peak: 0)
        useAdsr*: bool
        # feedback*: float32
        prev: float64 = 0
        curr: float64 = 0
        buffer: array[4096*8, float64]

proc constructFastFeedbackModule*(): FastFeedbackModule =
    var module = new FastFeedbackModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: FastFeedbackModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    # if(module.inputs[0].moduleIndex < 0): 
    #     module.prev = 0
    #     module.curr = 0
    #     return 0
    

    if(module.update):
        if(module.inputs[0].moduleIndex < 0):
            for i in 0..<synthInfos.waveDims.x * synthInfos.oversample:
                module.prev = 0
                module.curr = 0
                module.buffer[i] = 0
            return 0
        let moduleA = moduleList[module.inputs[0].moduleIndex]
        if(moduleA == nil):
            for i in 0..<synthInfos.waveDims.x * synthInfos.oversample:
                module.prev = 0
                module.curr = 0
                module.buffer[i] = 0
            return 0
        else:
            let l = synthInfos.waveDims.x * synthInfos.oversample
            let fb = module.fbEnvelope.doAdsr(synthInfos.macroFrame)
            var output = 0.0
            for i in 0..<l:
                let x1 = (i.float64 * PI * 2) / l.float64
                output = moduleA.synthesize(moduloFix(x1 + ((module.curr + module.prev)/2) * fb, (2 * PI).float64), pin, moduleList, synthInfos)
                # echo x
                module.buffer[i] = output
                module.prev = module.curr
                module.curr = output
            for i in 0..<l:
                let x1 = (i.float64 * PI * 2) / l.float64
                output = moduleA.synthesize(moduloFix(x1 + ((module.curr + module.prev)/2) * fb, (2 * PI).float64), pin, moduleList, synthInfos)
                # echo x
                module.buffer[i] = output
                module.prev = module.curr
                module.curr = output
        module.update = false

    # echo module.buffer[((x / (2 * PI)) * (synthInfos.waveDims.x * synthInfos.oversample).float64).int]
    return module.buffer[((x / (2 * PI)) * (synthInfos.waveDims.x * synthInfos.oversample).float64).int]


import ../serializationObject
import flatty

method serialize*(module: FastFeedbackModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.FAST_FEEDBACK, data: toFlatty(module))