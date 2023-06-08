# import module
# import ../globals
# import ../utils/utils
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
#     let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]

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
import ../globals
import ../utils/utils
import math

type
    FeedbackModule* = ref object of SynthModule
        fbEnvelope*: Adsr = Adsr(peak: 0)
        useAdsr*: bool
        # feedback*: float32
        prev: float64
        curr: float64
        buffer: array[1 shl 15, float64]

proc constructFeedbackModule*(): FeedbackModule =
    var module = new FeedbackModule
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
    ]
    module.outputs = @[Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize(module: FeedbackModule, x: float64, pin: int): float64 =
    if(module.inputs[0].moduleIndex < 0): return 0
    let moduleA = synthContext.moduleList[module.inputs[0].moduleIndex]

    var x1 = 0.0
    var res = 0.0
    const delta = 1.0 / 4096.0
    var phase = 0.0

    let fb = if(module.useAdsr): module.fbEnvelope.doAdsr() else: module.fbEnvelope.peak

    if(module.update):
        if(moduleA == nil):
            while(x1 < PI * 2):
                module.prev = 0
                module.buffer[(x1 / delta).int] = 0
                x1 += delta
        else:
            while(x1 < PI * 4):
                phase += delta + (moduleA.synthesize(phase, module.inputs[0].pinIndex) - (module.prev.float64)) * fb
                # res = moduleA.synthesize(x1 + module.prev * (module.feedback / 4))
                module.prev = res
                res = moduleA.synthesize(phase, module.inputs[0].pinIndex)
                module.buffer[(moduloFix(x1, PI * 2) / delta).int] = res
                x1 += delta
        module.update = false

    if(moduleA == nil):
        return 0.0

    module.prev = 0
    module.curr = 0
    let a = module.buffer[math.floor(moduloFix(x, PI * 2)/delta).int] 
    # let b = module.buffer[math.ceil(moduloFix(x, 1)/delta + 1).int mod 4095]
    # return (a + b) / 2
    return a

import ../serializationObject
import flatty

method serialize*(module: FeedbackModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.FEEDBACK, data: toFlatty(module))