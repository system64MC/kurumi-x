import ../kurumiX/synthesizer/synth
# import modules/outputModule
import utils
import math
import std/marshal
import imgui

import nglfw
import opengl
import textures

type
    SynthMode* = enum
        NONE,
        KURUMI_X
        KURUMI_3

var algsTextures*: array[42, GLuint]

proc loadAlgsText*() =
    # loadExtensions()
    for i in 0..<42:
        var myTexId: GLuint
        # glCreateTextures(GL_TEXTURE_2D, 1, myTexId.addr)
        glGenTextures(1, myTexId.addr)
        glBindTexture(GL_TEXTURE_2D, myTexId)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.ord)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.ord)
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RGBA.GLint,
            GLsizei(64),
            GLsizei(32),
            0,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            algsTex[64 * 32 * 4 * i].addr
        )
        algsTextures[i] = myTexId

# var myTextureId: Gluint
#   var myTextureId: Gluint
#   echo(myTextureId)
#   glGenTextures(1, myTextureId.addr)
#   glBindTexture(GL_TEXTURE_2D, myTextureId)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.ord)
#   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.ord)
#   glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
#   glTexImage2D(
#     GL_TEXTURE_2D,
#     0,
#     GL_BGRA.ord,
#     GLsizei(384),
#     GLsizei(216),
#     0,
#     GL_BGRA,
#     GL_UNSIGNED_BYTE,
#     tex.addr
#   )

# igImage(
#             cast[ImTextureID](myTextureId),
#             # ImVec2(x: 384 * (sizX / 384), y: 216 * (sizY / 216)),
#             ImVec2(x: 384 * mult.float32, y: 216 * mult.float32),
#             Imvec2(x: 0, y: 0), # uv0
#             Imvec2(x: 1, y: 1), # uv1
#             ImVec4(x: 1, y: 1, z: 1, w: 1), # tint color
#             # ImVec4(x: 1, y: 1, z: 1, w: 0.5f) # border color
#         )

var synthMode*: SynthMode

var window*: nglfw.Window
var context*: ptr ImGuiContext

var synthContext*: Synth = Synth()

# type SynthRef = Synth

var selectedLink* = Link(moduleIndex: -1, pinIndex: -1)
var isSelectorOpen* = true

proc linearInterpolation*(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))

proc moduloFix*(a, b: float64): float64 =
    return ((a mod b) + b) mod b

import constants
method doAdsr*(env: Adsr, macFrame: int32): float64 {.base.} =
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

when defined(emscripten):
    import jsbind/emscripten
    proc emscripten_run_script*(script: static cstring) {.importc.}

    proc setClipboardText*(text: string) {.EMSCRIPTEN_KEEPALIVE.} =
        discard EM_ASM_INT("""navigator.clipboard.writeText(UTF8ToString($0));""", text.cstring)
        
    # proc simulateGenerate() {.exportc.}

#     proc downloadBytes*(data: ptr, size: int32, fileName: string) =
        
#         discard EM_ASM_INT("""
#     const a = document.createElement('a');
#     a.style = 'display:none';
#     document.body.appendChild(a);
#     var view = new Uint8Array(Module['wasmMemory'].buffer, $0, $1);
#     var result = new Uint8Array($1);
#     for(var i = 0; i < $1; i++) { result[i] = view[i]; }
#     var blob = new Blob([result], {
#         type: 'application/octet-stream'
#     });
#     const url = URL.createObjectURL(blob);
#     a.href = url;
#     const filename = UTF8ToString($2);
#     a.download = filename;
#     a.click();
#     URL.revokeObjectURL(url);
#     document.body.removeChild(a);
# """, data, size, fileName.cstring)

    proc getByte*(address: uint32): int {.EMSCRIPTEN_KEEPALIVE, cdecl.} =
        let point = cast[ptr byte](address)
        return point[].int

    proc setByte*(address: uint32, value: uint32): int32 {.EMSCRIPTEN_KEEPALIVE, cdecl.} =
        let point = cast[ptr byte](address)
        point[] = value.uint8
        return 0

    proc downloadBytes*(data: ptr, size: int32, fileName: string) =
        
        discard EM_ASM_INT("""
    const a = document.createElement('a');
    a.style = 'display:none';
    document.body.appendChild(a);
    var result = new Uint8Array($1);
    for(var i = 0; i < $1; i++) { 
        result[i] = Module._getByte($0 + i); 
    }
    var blob = new Blob([result], {
        type: 'application/octet-stream'
    });
    const url = URL.createObjectURL(blob);
    a.href = url;
    const filename = UTF8ToString($2);
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
    document.body.removeChild(a);
""", data, size, fileName.cstring)

    