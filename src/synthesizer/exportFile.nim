import globals
import synthesizeWave
import flatty
import synth
import utils/utils
import supersnappy
import modules
import serializationObject
import serialization
import print
import strformat

import imgui, imgui/[impl_opengl, impl_glfw]#, nimgl/imnodes
import nimgl/[opengl, glfw]

import tinydialogs
import parseutils

import streams
import os
import math
import browsers

proc getSampleRate(synth: ref Synth): int =
    return int(floor((440 * float64(synth.synthInfos.waveDims.x)) / 2.0))

proc drawPopup(currFrame, maxFrame: int): void {.inline.} =
    igRender()
    glfwPollEvents()


    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()
    
    if(igBeginPopupModal("Exporting sequence", nil, flags = ImGuiWindowFlags.NoResize)):
        igText(("Exporting Wave " & $currFrame & " over " & $maxFrame & "...").cstring)
        echo "Window drawn"
        igEndPopup()
    igRender()

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    window.swapBuffers()
    glfwSwapInterval(1)

proc saveWav*(data: string, bits: int = 16, sequence: bool = false): void {.gcsafe.} =
    let path = saveFileDialog("Export .WAV", getCurrentDir() / "\0", ["*.wav"], ".WAV files")
    if(path == ""): return

    var synth = loadStateHistory(data)
    # var seqFrame = 0
     
    let f = open(path, fmWrite)
    defer: f.close()

    var frames = 1
    if sequence:
        frames = synth.synthInfos.macroLen

    var chunkSize = 0
    if bits == 16:
        chunkSize = 36 + (synth.synthInfos.waveDims.x * frames) * 2
    else:
        chunkSize = 36 + (synth.synthInfos.waveDims.x * frames)

    var subchunkSize = 0
    if bits == 16:
        subchunkSize = (synth.synthInfos.waveDims.x * frames) * 2
    else:
        subchunkSize = (synth.synthInfos.waveDims.x * frames)

    let sampleRate: int = synth.getSampleRate()
    var byteRate = 0
    if bits == 16:
        byteRate = (sampleRate * 16) div 8
    else:
        byteRate = sampleRate

    let header: seq[byte] = @[
        0x52, 0x49, 0x46, 0x46, # ChunkID: "RIFF" in ASCII form, big endian
        byte(chunkSize and 0xFF), byte((chunkSize shr 8) and 0xFF), byte((chunkSize shr 16) and 0xFF), byte(chunkSize shr 24), # ChunkSize - will be filled later,
        0x57, 0x41, 0x56, 0x45, # Format: "WAVE" in ASCII form
        0x66, 0x6d, 0x74, 0x20, # Subchunk1ID: "fmt " in ASCII form
        0x10, 0x00, 0x00, 0x00, # Subchunk1Size: 16 for PCM
        0x01, 0x00, # AudioFormat: PCM = 1
        0x01, 0x00, # NumChannels: Mono = 1
        byte(sampleRate and 0xFF), byte((sampleRate shr 8) and 0xFF), byte((sampleRate shr 16) and 0xFF), byte(sampleRate shr 24), # SampleRate: 44100 Hz - little endian
        byte(byteRate and 0xFF), byte((byteRate shr 8) and 0xFF), byte((byteRate shr 16) and 0xFF), byte(byteRate shr 24), # ByteRate: 44100 * 1 * 16 / 8 - little endian
        byte(bits div 8), 0x00, # BlockAlign: 1 * 16 / 8 - little endian
        bits.byte, 0x00, # BitsPerSample: 16 bits per sample
        0x64, 0x61, 0x74, 0x61, # Subchunk2ID: "data" in ASCII form
        byte(subchunkSize and 0xFF), byte((subchunkSize shr 8) and 0xFF), byte((subchunkSize shr 16) and 0xFF), byte(subchunkSize shr 24), # Subchunk2Size - will be filled later
    ]
    
    discard f.writeBytes(header, 0, header.len)

    let wavDiv = synth.synthInfos.waveDims.y.float64 / 2.0
    let waveDiv05 = wavDiv + 0.5

    if(sequence):
        # igOpenPopup("Exporting sequence")
        let tmpMac = synth.synthInfos.macroFrame
        for i in 0..<synth.synthInfos.macroLen:
            synth.synthInfos.macroFrame = i
            # seqFrame = i
            synth.synthesize()

            for j in 0..<synth.synthInfos.waveDims.x:
                var sample = synth.outputInt[j].float64
                if((synth.synthInfos.waveDims.y and 0x0001) == 1):
                    sample = sample / waveDiv05
                else:
                    sample = sample / wavDiv
                
                if(bits == 16):
                    let myOut = (round((sample - 1) * ((1 shl (16-1))-1).float64)).int16
                    let b1 = (myOut and 0xFF).byte
                    let b2 = (myOut shr 8).byte
                    discard f.writeBytes(@[b1, b2], 0, 2)
                    continue

                let myOut = (round((sample) * ((1 shl (8 - 1))).float64)).int16
                discard f.writeBytes(@[myOut.byte], 0, 1)
            # drawPopup(seqFrame, synthContext.macroLen - 1)

        synth.synthInfos.macroFrame = tmpMac
        synth.synthesize()
        # igCloseCurrentPopup()
    else:
        synth.synthesize()
        for j in 0..<synth.synthInfos.waveDims.x:
            var sample = synth.outputInt[j].float64
            if((synth.synthInfos.waveDims.y and 0x0001) == 1):
                sample = sample / waveDiv05
            else:
                sample = sample / wavDiv
            
            if(bits == 16):
                let myOut = (round((sample - 1) * ((1 shl (16-1))-1).float64)).int16
                let b1 = (myOut and 0xFF).byte
                let b2 = (myOut shr 8).byte
                discard f.writeBytes(@[b1, b2], 0, 2)
                continue

            let myOut = (round((sample) * ((1 shl (8 - 1))).float64)).int16
            discard f.writeBytes(@[myOut.byte], 0, 1)
    # notifyPopup("Kurumi-X", "WAV file " & path.splitFile().name & " exported!", IconType.Info)
    discard messageBox("Kurumi-X", fmt"{path.splitFile().name}.wav is exported with success!", DialogType.Ok, IconType.Info, Button.Yes)

proc saveN163*(data: string, sequence: bool): void {.gcsafe.} =
    let path = saveFileDialog("Export .FTI", getCurrentDir() / "\0", ["*.fti"], ".FTI files")
    if(path == ""): return
    
    var synth = loadStateHistory(data)
    let tmpLen = synth.synthInfos.waveDims.x
    let tmpHei = synth.synthInfos.waveDims.y

    if(tmpLen > 240):
        synth.synthInfos.waveDims.x = 240
    if(tmpHei > 15):
        synth.synthInfos.waveDims.y = 15
    synth.synthesize()

    var name = path.splitFile().name

    if name.len > 127:
        name = name.substr(0, 127)

    let f = open(path, fmWrite)
    defer: f.close()

    let header: seq[byte] = @[
        'F'.byte, 'T'.byte, 'I'.byte, '2'.byte, '.'.byte, '4'.byte, # Header
        0x05, # Instrument type, 05 for N163
        (name.len).byte, 0, 0, 0 # Length of name string
    ]

    discard f.writeBytes(header, 0, header.len)
    
    for c in name:
        discard f.writeBytes(@[c.byte], 0, 1)
    # discard f.writeBytes(@[0x00'u8], 0, 1)
    
    discard f.writeBytes(@[0x05'u8], 0, 1)

    discard f.writeBytes(@[0x00'u8], 0, 1)
    discard f.writeBytes(@[0x00'u8], 0, 1)
    discard f.writeBytes(@[0x00'u8], 0, 1)
    discard f.writeBytes(@[0x00'u8], 0, 1)

    var waveMacroEnabled = 0'u8
    if sequence:
        waveMacroEnabled = 1
    discard f.writeBytes(@[waveMacroEnabled], 0, 1)

    if(sequence):
        let macLen = min(synth.synthInfos.macroLen, 64)
        discard f.writeBytes(@[macLen.byte], 0, 1)
        
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)

        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)
        discard f.writeBytes(@[0xFF'u8], 0, 1)

        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)

        for i in 0..<macLen:
            discard f.writeBytes(@[i.byte], 0, 1)

        discard f.writeBytes(@[synth.synthInfos.waveDims.x.byte], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)

        discard f.writeBytes(@[macLen.byte], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        
        let tmpMac = synth.synthInfos.macroFrame
        for m in 0..<macLen:
            synth.synthInfos.macroFrame = m
            synth.synthesize()

            for i in 0..<synth.synthInfos.waveDims.x:
                let smp = synth.outputInt[i]
                discard f.writeBytes(@[smp.byte], 0, 1)

        synth.synthInfos.macroFrame = tmpMac

    else:
        discard f.writeBytes(@[synth.synthInfos.waveDims.x.byte], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)

        discard f.writeBytes(@[0x01'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        discard f.writeBytes(@[0x00'u8], 0, 1)
        for i in 0..<synth.synthInfos.waveDims.x:
                let smp = outputInt[i]
                discard f.writeBytes(@[smp.byte], 0, 1)

    synth.synthInfos.waveDims.x = tmpLen
    synth.synthInfos.waveDims.y = tmpHei
    synth.synthesize()
    notifyPopup("Kurumi-X", "FTI instrument " & name & " exported!", IconType.Info)
    discard messageBox("Kurumi-X", fmt"FTI instrument {path.splitFile().name}.fti is exported with success!", DialogType.Ok, IconType.Info, Button.Yes)

const FURNACE_FORMAT_VER: uint16 = 143
proc saveFUW*(): void =
    let path = saveFileDialog("Export .FUW", getCurrentDir() / "\0", ["*.fuw"], ".FUW files")
     
    let f = open(path, fmWrite)
    defer: f.close()

    let size: uint32 = 1 + 4 + 4 + 4 + (4 * synthContext.synthInfos.waveDims.x).uint32
    const HEADER_SIZE = 16 + 2 + 2 + 4 + 4 + 1 + 4 + 4 + 4

    let header: seq[byte] = @[
        '-'.byte, 'F'.byte, 'u'.byte, 'r'.byte, 'n'.byte, 'a'.byte, 'c'.byte, 'e'.byte, ' '.byte, 'w'.byte, 'a'.byte, 'v'.byte, 'e'.byte, 't'.byte, 'a'.byte, '-'.byte, # Header, 16 bytes
        byte(FURNACE_FORMAT_VER and 0xFF), byte(FURNACE_FORMAT_VER shr 8), # Format version, 2 bytes
        '0'.byte, '0'.byte, # Reserved, 2 bytes
        'W'.byte, 'A'.byte, 'V'.byte, 'E'.byte, # WAVE chunk, 4 bytes
        byte(size and 0xFF), byte((size shr 8) and 0xFF), byte((size shr 16) and 0xFF), byte((size shr 24)), # Size of chunk, 4 bytes
        0, # empty string, 1 byte
        byte(synthContext.synthInfos.waveDims.x and 0xFF), byte((synthContext.synthInfos.waveDims.x shr 8) and 0xFF), byte((synthContext.synthInfos.waveDims.x shr 16) and 0xFF), byte((synthContext.synthInfos.waveDims.x shr 24)), # Wave length, 4 bytes
        0, 0, 0, 0, # Reserved, 4 bytes
        byte(synthContext.synthInfos.waveDims.y and 0xFF), byte((synthContext.synthInfos.waveDims.y shr 8) and 0xFF), byte((synthContext.synthInfos.waveDims.y shr 16) and 0xFF), byte((synthContext.synthInfos.waveDims.y shr 24)), # Wave height, 4 bytes
    ]

    discard f.writeBytes(header, 0, header.len)

    for i in 0..<synthContext.synthInfos.waveDims.x:
        let smp = outputInt[i]
        discard f.writeBytes(@[(smp and 0xFF).byte], 0, 1)
        discard f.writeBytes(@[((smp shr 8) and 0xFF).byte], 0, 1)
        discard f.writeBytes(@[((smp shr 16) and 0xFF).byte], 0, 1)
        discard f.writeBytes(@[((smp shr 25)).byte], 0, 1)

    notifyPopup("Kurumi-X", "FUW file " & path.splitFile().name & " exported!", IconType.Info)

proc saveDMW*(): void =
    openDefaultBrowser("https://tildearrow.org/?p=post&month=5&year=2021&item=delek")
    openDefaultBrowser("https://tildearrow.org/?p=post&month=7&year=2022&item=deflebrain")
    openDefaultBrowser("https://github.com/tildearrow/furnace")
    return