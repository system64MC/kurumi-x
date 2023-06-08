type
    VecI32* = object
        x*, y*: int32
    
    Adsr* = object
        start*    : float32
        attack*   : int32
        peak*     : float32
        decay*    : int32
        sustain*  : float32
        attack2*  : int32
        peak2*    : float32
        decay2*   : int32
        sustain2* : float32

    Link* = object
        moduleIndex* : int16
        pinIndex*: int16