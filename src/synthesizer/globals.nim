import synth
# import modules/outputModule
import ./utils/utils
import math
import std/marshal
import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]

var window*: GLFWWindow

var synthContext*: ref Synth = (ref Synth)()

type SynthRef = ref Synth

var selectedLink* = Link(moduleIndex: -1, pinIndex: -1)

var outputFloat*: array[4096 * 8, float64]
var outputInt*: array[4096, int32]

proc linearInterpolation*(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))

proc moduloFix*(a, b: float64): float64 =
    return ((a mod b) + b) mod b

method doAdsr*(envelope: Adsr, macFrame: int32): float64 {.base.} =
    let mac = macFrame.float64
    let env = envelope
    # Attack
    if(mac <= env.attack.float64):
        if(env.attack <= 0):
            return env.peak
        return linearInterpolation(0, env.start.float64, env.attack.float64, env.peak.float64, mac.float64)
    
    # Decay and sustain
    if(mac > env.attack.float64 and mac <= env.attack.float64 + env.decay.float64):
        if(env.decay <= 0):
            return (env.sustain.float64)
        return linearInterpolation(env.attack.float64, env.peak.float64, (env.attack + env.decay).float64, env.sustain.float64, mac.float64)
    
    # Attack2
    if(mac > env.attack.float64 + env.decay.float64 and mac <= env.attack.float64 + env.decay.float64 + env.attack2.float64):
        if(env.attack2 < 0):
            return (env.peak2.float64)
        return linearInterpolation(env.attack.float64 + env.decay.float64, env.sustain.float64, (env.attack + env.decay + env.attack2).float64, env.peak2.float64, mac.float64)

    # Decay2 and sustain2
    if(mac > env.attack.float64 + env.decay.float64 + env.attack2.float64 and mac <= env.attack.float64 + env.decay.float64 + env.attack2.float64 + env.decay2.float64):
        if(env.attack2 < 0):
            return (env.sustain2.float64)
        return linearInterpolation(env.attack.float64 + env.decay.float64 + env.attack2.float64, env.peak2.float64, (env.attack + env.decay + env.attack2 + env.decay2).float64, env.sustain2.float64, mac.float64)

    return env.sustain2


        
    