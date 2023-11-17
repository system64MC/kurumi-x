import ../synthesizer/serialization
import ../../common/globals

type
    HistoryEvent* = object
        eventName*: string
        synthState*: string
    
    History* = object
        historyPointer*: int = 0
        historyStack*: seq[HistoryEvent]

var history*: History
proc registerHistoryEvent*(eventName: string): void =
    history.historyStack.setLen(history.historyPointer + 2)
    let e = HistoryEvent(eventName: eventName, synthState: synthContext.saveStateHistory())
    history.historyStack[history.historyStack.len - 1] = e
    history.historyPointer = history.historyStack.len - 1
    # echo eventName
    # echo history.historyStack.len

proc undo*(): void =
    history.historyPointer.dec
    let e = history.historyStack[history.historyPointer]
    synthContext = loadStateHistory(e.synthState)

proc redo*(): void =
    history.historyPointer.inc
    let e = history.historyStack[history.historyPointer]
    synthContext = loadStateHistory(e.synthState)

proc restoreToHistoryIndex*(index: int): void =
    history.historyPointer = index
    let e = history.historyStack[index]
    synthContext = loadStateHistory(e.synthState)