import ../../common/constants

type
    Adsr* = object
        mac*: seq[byte] = @[255]
        macString*: string = "255"
        start*: float32
        attack*: int32
        decay*: int32
        sustain*: float32
        peak*: float32
        mode*: int32

proc linearInterpolation*(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))

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
        

        return env.sustain

    of 2:
        if(env.mac.len == 0): return env.peak
        return env.peak * volROM[env.mac[min(macFrame, env.mac.len - 1)]]
    else:
        return 0.0

import strutils
proc refreshAdsr*(env: ptr Adsr) =
    env.mac = @[]
    for num in env.macString.split:
        try:
            let smp = parseUInt(num).uint8
            env.mac.add(smp)
        except ValueError:
            continue
    if env.mac.len == 0:
        env.mac = @[255]

proc newAdsr(start: float32, attack, decay: int32, sustain: float32): Adsr =
    return Adsr(start: start, attack: attack, decay: decay, sustain: sustain)
