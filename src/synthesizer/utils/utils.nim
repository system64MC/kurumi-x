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

    Link* = object
        moduleIndex* : int16
        pinIndex*: int16

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