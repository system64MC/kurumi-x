import ../../common/globals
import math
import synth

var tempFloat*: array[4096 * 8, float64]

const FIR_ORDER = 15
const SMP_LEN = 4096 * 8

proc sinc(x: float64): float64 =
    if(x == 0): return 1
    return math.sin(PI*x)/(PI*x)

proc moduloFix*(a, b: int): int =
    return ((a mod b) + b) mod b

# proc resample*(): void =
#     let ratio = (4096.0 * 8.0) / synthContext.synthInfos.waveDims.x.float64
#     var firCoeficients: array[FIR_ORDER, float64]
# 
#     for k in 0..<FIR_ORDER:
#         firCoeficients[k] = sinc(k.float64/ratio)/ratio
# 
#     for i in 0..<(4096 * 8):
#         var accumulator = synthContext.outputFloat[i] * firCoeficients[0]
#         for k in countdown(FIR_ORDER-1, 0):
#             accumulator += firCoeficients[k] * synthContext.outputFloat[moduloFix(i+k, SMP_LEN)]
#             accumulator += firCoeficients[k] * synthContext.outputFloat[moduloFix(i-k, SMP_LEN)]
#         tempFloat[i] = accumulator
#     
#     for i in 0..<synthContext.synthInfos.waveDims.x:
#         let a = i.float64 * ratio
#         var acc = 0.0
#         for j in (a.int - FIR_ORDER)..(a.int + FIR_ORDER):
#             var smp = 0.0
#             smp = tempFloat[moduloFix(j, SMP_LEN)]
#             acc += smp * sinc(a - j.float64)
#         var value = min(max(acc, -1.0), 1.0) + 1
#         synthContext.outputInt[i] = round(value * (synthContext.synthInfos.waveDims.y.float64 / 2.0)).int32