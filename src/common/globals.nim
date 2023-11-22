import ../kurumiX/synthesizer/synth
import ../kurumi3/synth/kurumi3synth
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
var kurumi3SynthContext*: Kurumi3Synth

# when defined(emscripten):
#     let chan

# type SynthRef = Synth

var selectedLink* = Link(moduleIndex: -1, pinIndex: -1)
var isSelectorOpen* = true



proc moduloFix*(a, b: float64): float64 =
    return ((a mod b) + b) mod b



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

    proc getMaxWidth2(): int32 {.EMSCRIPTEN_KEEPALIVE.} = 
        return EM_ASM_INT("""
        return screen.width;
    """)

    proc getMaxHeight2(): int32 {.EMSCRIPTEN_KEEPALIVE.} = 
        return EM_ASM_INT("""
        return screen.height;
    """)

    proc setFullScreen*() =
        discard EM_ASM_INT("""
        //Module.requestFullscreen(true, true);
    """)
        window.setWindowSize(getMaxWidth2(), getMaxHeight2())

    