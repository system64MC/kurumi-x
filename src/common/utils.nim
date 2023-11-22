type
    VecI32* = object
        x*, y*: int32
    
    Adsr* = object
        mac*: seq[byte] = @[255]
        macString*: string = "255"
        start*    : float32
        attack*   : int32
        peak*     : float32
        decay*    : int32
        sustain*  : float32
        attack2*  : int32
        peak2*    : float32
        decay2*   : int32
        sustain2* : float32
        mode*: int32

    AdsrSerialize* = object
        mac*: seq[byte] = @[255]
        start*    : float32
        attack*   : int32
        peak*     : float32
        decay*    : int32
        sustain*  : float32
        attack2*  : int32
        peak2*    : float32
        decay2*   : int32
        sustain2* : float32
        mode*: int32

    Link* = object
        moduleIndex* : int16
        pinIndex*: int16

proc serializeAdsr*(adsr: Adsr): AdsrSerialize =
    return AdsrSerialize(
        mac: adsr.mac,
        start: adsr.start,
        attack: adsr.attack,
        peak: adsr.peak,
        decay: adsr.decay,
        sustain: adsr.sustain,
        attack2: adsr.attack2,
        peak2: adsr.peak2,
        decay2: adsr.decay2,
        sustain2: adsr.sustain2,
        mode: adsr.mode
    )

import strutils
method refreshAdsr*(env: ptr Adsr) {.base.} =
    env.mac = @[]
    for num in env.macString.split:
        try:
            let smp = parseUInt(num).uint8
            env.mac.add(smp)
        except ValueError:
            continue
    if env.mac.len == 0:
        env.mac = @[255]

proc linearInterpolation*(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))

import constants
proc doAdsr*(env: Adsr, macFrame: int32): float64 =
    let mac = macFrame.float64
    # let env = envelope

    case env.mode:
    of 0:
        return env.peak
    of 1:
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

    of 2:
        if(env.mac.len == 0): return env.peak
        return env.peak * volROM[env.mac[min(macFrame, env.mac.len - 1)]]
    else:
        return 0.0