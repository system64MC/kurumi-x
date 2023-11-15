# import ../synthesizer/serialization
# import ../synthesizer/globals
import ../synth/kurumi3synth
import ../synth/globals
import ../synth/serialization

type
    History3Event* = object
        eventName*: string
        synthState*: string
    
    History3* = object
        historyPointer*: int = 0
        historyStack*: seq[History3Event]

var k3history*: History3
proc registerHistoryEvent*(eventName: string): void =
    k3history.historyStack.setLen(k3history.historyPointer + 2)
    let e = History3Event(eventName: eventName, synthState: kurumi3SynthContext.saveStateHistory())
    k3history.historyStack[k3history.historyStack.len - 1] = e
    k3history.historyPointer = k3history.historyStack.len - 1
    # echo eventName
    # echo history.historyStack.len

proc undo*(): void =
    k3history.historyPointer.dec
    let e = k3history.historyStack[k3history.historyPointer]
    kurumi3SynthContext = loadStateHistory(e.synthState)

proc redo*(): void =
    k3history.historyPointer.inc
    let e = k3history.historyStack[k3history.historyPointer]
    kurumi3SynthContext = loadStateHistory(e.synthState)

proc restoreToHistoryIndex*(index: int): void =
    k3history.historyPointer = index
    let e = k3history.historyStack[index]
    kurumi3SynthContext = loadStateHistory(e.synthState)