import supersnappy
import flatty
import kurumi3Synth
import adsr, operator
import ../../synthesizer/synthInfos

proc saveStateHistory*(synth: Kurumi3Synth): string =
    let str = "KRUL" & compress(toFlatty(synth))
    return str

proc loadStateHistory*(data: string): Kurumi3Synth =
    let str = data
    if(str.substr(0, "KRUL".len - 1) != "KRUL"): return
    let data = str.substr("KRUL".len).uncompress().fromFlatty(Kurumi3Synth)
    return data
    