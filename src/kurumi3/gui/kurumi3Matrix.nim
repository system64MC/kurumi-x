import imgui
import ../synth/globals
import ../synth/serialization
import ../synth/kurumi3Synth
import ../synth/constants
import kurumi3History

proc applyAlg(alg: int) =
    case alg
    # --------------------< 2 OPERATORS >--------------------
    of 0:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 0, 0, 0, 0, 0, 0]
    
    of 1:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 0, 0, 0, 0, 0, 0]

    # --------------------< 3 OPERATORS >--------------------
    of 2:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 0, 0, 0, 0, 0]
    
    of 3:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 0, 1, 0, 0, 0, 0, 0]

    of 4:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 1, 0, 0, 0, 0, 0]

    of 5:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 0, 0, 0, 0, 0]

    of 6:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 1, 0, 0, 0, 0, 0]

    # --------------------< 4 OPERATORS >--------------------
    of 7:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]

    of 8:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]
        
    of 9:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            1, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]

    of 10:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 0, 1, 0, 0, 0, 0]

    of 11:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 1, 1, 0, 0, 0, 0]

    of 12:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]    
        kurumi3SynthContext.opOuts = [0, 1, 1, 1, 0, 0, 0, 0]

    of 13:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 1, 1, 0, 0, 0, 0]

    of 14:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]

    of 15:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 1, 0, 0, 0, 0]

    of 16:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 1, 0, 0, 0, 0]

    of 17:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 1, 1, 0, 0, 0, 0]

    of 18:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 1, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]

    # --------------------< 6 OPERATORS >--------------------
    
    of 19:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 0, 0, 1, 0, 0]

    of 20:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 1, 0, 0]

    of 21:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 0, 0, 1, 0, 0]

    of 22:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 0, 1, 0, 1, 0, 0]

    of 23:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 1, 0, 0]

    of 24:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 0, 0, 1, 0, 0]

    of 25:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 1, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 0, 1, 1, 0, 0]

    of 26:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 1, 0, 0]

    of 27:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 1, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 0, 0, 1, 0, 0]

    of 28:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 1, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 0, 0, 1, 0, 0]

    of 29:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 1, 0, 1, 1, 0, 0]

    of 30:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 1, 0, 0, 1, 0, 0]

    of 31:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 1, 0, 1, 1, 0, 0]

    of 32:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 1, 0, 1, 1, 1, 0, 0]

    of 33:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 0, 1, 0, 1, 1, 0, 0]

    of 34:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 0, 1, 1, 1, 0, 0]

    of 35:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 1, 0, 1, 1, 0, 0]

    of 36:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 0, 1, 0, 0, 1, 0, 0]

    of 37:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 0, 0, 1, 0, 1, 0, 0]

    of 38:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 0, 1, 0, 1, 0, 0]

    of 39:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 0, 0, 1, 1, 0, 0]

    of 40:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 1, 1, 0, 1, 0, 0]

    of 41:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [1, 1, 1, 1, 1, 1, 0, 0]
        
    else:
        kurumi3SynthContext.modMatrix = [
            0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        kurumi3SynthContext.opOuts = [0, 0, 0, 1, 0, 0, 0, 0]


    

    kurumi3SynthContext.synthesize()
    registerHistoryEvent("Apply alg preset")

proc drawMatrix(): void {.inline.} =
    igBeginChild("mat")
    # if(igBeginTable("opMatrix", 4, flags = (ImGuiTableFlags.SizingFixedSame.int).ImGuiTableFlags)):
    if(igBeginTable("opMatrix", 8, ImGuiTableFlags.SizingStretchSame)):
        for i in 0..<NB_OPS:
            for j in 0..<NB_OPS:
                let index = i * 8 + j
                igTableNextColumn()
                # igBeginChild(($index).cstring, ImVec2(x: 128, y: 40), true, ImGuiWindowFlags.NoResize)
                # igBeginChild(($index).cstring, ImVec2(x: 128, y: 40), true, ImGuiWindowFlags.NoResize)
                # igBeginChild(($index).cstring, ImVec2(x: igGetColumnWidth(), y: 40), true, ImGuiWindowFlags.AlwaysAutoResize)
                let avReg = ImVec2()
                igGetContentRegionAvailNonUDT(avReg.addr)
                igSetNextItemWidth(avReg.x)
                if(igSliderFloat(("##opSlider" & $i & $j).cstring, kurumi3synthContext.modMatrix[index].addr, 0, 4)):
                    kurumi3synthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit FM Modulation Matrix")        
        igEndTable()
    igEndChild()

import ../../synthesizer/globals
import math
proc drawMatrixWindow*(): void {.inline} =
    igBegin("Modulation Matrix")
    if(igBeginTabBar("tabs")):
        if(igBeginTabItem("Matrix")):
            drawMatrix()
            igEndTabItem()
        if(igBeginTabItem("Out. Levels")):
            igBeginChild("outs")
            for i in 0..<NB_OPS:
                let avReg = ImVec2()
                igGetContentRegionAvailNonUDT(avReg.addr)
                igSetNextItemWidth(avReg.x - 64)
                if(igSliderFloat(("OP " & $i).cstring, kurumi3SynthContext.opOuts[i].addr, 0, 4)):
                    kurumi3SynthContext.synthesize()
                if(igIsItemDeactivated()):
                    registerHistoryEvent("Edit Op. output level")
            igEndChild()
            igEndTabItem()
        if(igBeginTabItem("Presets")):
            var vec: ImVec2
            igBeginChild("algs2")
            igText("2 OP :")
            igGetWindowContentRegionMaxNonUDT(vec.addr)
            var w = vec.x
            var howManyCols = max((w / (64 * 2 + 16)).floor(), 1)
            var howManyLines = (2.0 / howManyCols).ceil()
            

            for i in 0..<howManyLines.int:
                for j in 0..<howManyCols.int:
                    let index = i * howManyCols.int + j
                    if index >= 2: break

                    let tex = algsTextures[index + 0]
    # proc igImageButton*(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2 = ImVec2(x: 0, y: 0), uv1: ImVec2 = ImVec2(x: 1, y: 1), frame_padding: int32 = -1, bg_col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: 0), tint_col: ImVec4 = ImVec4(x: 1, y: 1, z: 1, w: 1)): bool {.importc: "igImageButton".}
                    if igImageButton(
                        cast[ImTextureID](tex),
                        ImVec2(x: 64 * 2, y: 32 * 2),
                        Imvec2(x: 0, y: 0), # uv0
                        Imvec2(x: 1, y: 1), # uv1
                        tint_col = ImVec4(x: 1, y: 1, z: 1, w: 1), # tint colo
                    ):
                        applyAlg(index)
                    igSameLine()
                igNewLine()
            # igEndChild()

            igSeparator()

            # igBeginChild("algs3")
            igText("3 OP :")
            igGetWindowContentRegionMaxNonUDT(vec.addr)
            w = vec.x
            howManyCols = max((w / (64 * 2 + 16)).floor(), 1)
            howManyLines = (5.0 / howManyCols).ceil()
            

            for i in 0..<howManyLines.int:
                for j in 0..<howManyCols.int:
                    let index = i * howManyCols.int + j
                    if index >= 5: break

                    let tex = algsTextures[index + 2]
    # proc igImageButton*(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2 = ImVec2(x: 0, y: 0), uv1: ImVec2 = ImVec2(x: 1, y: 1), frame_padding: int32 = -1, bg_col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: 0), tint_col: ImVec4 = ImVec4(x: 1, y: 1, z: 1, w: 1)): bool {.importc: "igImageButton".}
                    if igImageButton(
                        cast[ImTextureID](tex),
                        ImVec2(x: 64 * 2, y: 32 * 2),
                        Imvec2(x: 0, y: 0), # uv0
                        Imvec2(x: 1, y: 1), # uv1
                        tint_col = ImVec4(x: 1, y: 1, z: 1, w: 1), # tint colo
                    ):
                        applyAlg(index + 2)
                    igSameLine()
                igNewLine()
            # igEndChild()

            igSeparator()

            # igBeginChild("algs4")
            igText("4 OP :")
            
            igGetWindowContentRegionMaxNonUDT(vec.addr)
            w = vec.x
            howManyCols = max((w / (64 * 2 + 16)).floor(), 1)
            howManyLines = (12.0 / howManyCols).ceil()
            

            for i in 0..<howManyLines.int:
                for j in 0..<howManyCols.int:
                    let index = i * howManyCols.int + j
                    if index >= 12: break

                    let tex = algsTextures[index + 7]
    # proc igImageButton*(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2 = ImVec2(x: 0, y: 0), uv1: ImVec2 = ImVec2(x: 1, y: 1), frame_padding: int32 = -1, bg_col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: 0), tint_col: ImVec4 = ImVec4(x: 1, y: 1, z: 1, w: 1)): bool {.importc: "igImageButton".}
                    if igImageButton(
                        cast[ImTextureID](tex),
                        ImVec2(x: 64 * 2, y: 32 * 2),
                        Imvec2(x: 0, y: 0), # uv0
                        Imvec2(x: 1, y: 1), # uv1
                        tint_col = ImVec4(x: 1, y: 1, z: 1, w: 1), # tint colo
                    ):
                        applyAlg(index + 7)
                    igSameLine()
                igNewLine()
            # igEndChild()

            igSeparator()

            # igBeginChild("algs6")
            igText("6 OP :")
            igGetWindowContentRegionMaxNonUDT(vec.addr)
            w = vec.x
            howManyCols = max((w / (64 * 2 + 16)).floor(), 1)
            howManyLines = (23.0 / howManyCols).ceil()
            

            for i in 0..<howManyLines.int:
                for j in 0..<howManyCols.int:
                    let index = i * howManyCols.int + j
                    if index >= 23: break

                    let tex = algsTextures[index + 19]
    # proc igImageButton*(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2 = ImVec2(x: 0, y: 0), uv1: ImVec2 = ImVec2(x: 1, y: 1), frame_padding: int32 = -1, bg_col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: 0), tint_col: ImVec4 = ImVec4(x: 1, y: 1, z: 1, w: 1)): bool {.importc: "igImageButton".}
                    if igImageButton(
                        cast[ImTextureID](tex),
                        ImVec2(x: 64 * 2, y: 32 * 2),
                        Imvec2(x: 0, y: 0), # uv0
                        Imvec2(x: 1, y: 1), # uv1
                        tint_col = ImVec4(x: 1, y: 1, z: 1, w: 1), # tint colo
                    ):
                        applyAlg(index + 19)
                    igSameLine()
                igNewLine()
            igEndChild()
                
                # else: igNewLine()
            igEndTabItem()
                # igImage(
                # cast[ImTextureID](tex),
                # # ImVec2(x: 384 * (sizX / 384), y: 216 * (sizY / 216)),
                # ImVec2(x: 384 * mult.float32, y: 216 * mult.float32),
                # Imvec2(x: 0, y: 0), # uv0
                # Imvec2(x: 1, y: 1), # uv1
                # ImVec4(x: 1, y: 1, z: 1, w: 1), # tint color
                # # ImVec4(x: 1, y: 1, z: 1, w: 0.5f) # border color
                # )
        igEndTabBar()
    igEnd()