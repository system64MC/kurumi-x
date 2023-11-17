import imgui

import moduleCreateMenu
import moduleDraw
import ../synthesizer/synth
import ../../common/globals
import ../../common/utils
import ../synthesizer/modules/outputModule
import ../synthesizer/modules/module
import ../synthesizer/serialization
import ../synthesizer/linkManagement
import ../synthesizer/synthesizeWave
import history

const
    WIN_PAD = 8.0f
    CELL_PAD_X = 8.0f
    CELL_PAD_Y = 4.0f
    CELL_SIZE_X = 256.0f + CELL_PAD_X
    CELL_SIZE_Y = 256.0f + CELL_PAD_Y
    BUTTON_SIZE_Y = 24.0f

proc `/`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x / vec2.x, y: vec1.y / vec2.y)

proc `+`(vec1, vec2: ImVec2): ImVec2 =
    return ImVec2(x: vec1.x + vec2.x, y: vec1.y + vec2.y)

var scrollPoint = ImVec2()

proc drawGrid*(): void {.inline.} =
    var style = igGetStyle().colors[ImGuiCol.ChildBg.int].addr
    let alpha = style.w
    style.w = 0
    if(igBeginTable("table", GRID_SIZE_X.int32, (ImGuiTableFlags.SizingFixedSame.int or ImGuiTableFlags.ScrollX.int or ImGuiTableFlags.ScrollY.int).ImGuiTableFlags)):
        for i in 0..<GRID_SIZE_Y:
            igTableNextRow()
            for j in 0..<GRID_SIZE_X:
                igTableNextColumn()
                let index = i * GRID_SIZE_X + j
                
                igBeginChild(($index).cstring, ImVec2(x: 256, y: 256), true, ImGuiWindowFlags.NoResize)
                drawModule(index, synthContext.moduleList)

                # igButton(("x:" & $j & " y:" & $i).cstring, ImVec2(x: 256, y: 256))
                igEndChild()
                drawModuleCreationContextMenu(index, synthContext.moduleList, synthContext.outputIndex)
                # Copy paste features
                if(igIsItemHovered()):
                    copyPasteOps(index, synthContext.moduleList, synthContext.outputIndex)
                continue
        scrollPoint.x = igGetScrollX()
        scrollPoint.y = igGetScrollY()
        igEndTable()
    style.w = alpha

    # Drawing links
    # var style = igGetStyleColorVec4(ImGuiCol.ChildBg)[]
    
    var dl = igGetWindowDrawList()
    var winPos = ImVec2()
    igGetWindowPosNonUDT(winPos.addr)
    for i in 0..<GRID_SIZE_Y:
        for j in 0..<GRID_SIZE_X:
            let index = i * GRID_SIZE_X + j
            let module = synthContext.moduleList[index]
            if(module == nil): continue
            # echo("x : " & $j & " y: " & $i)
            for x in 0..<module.outputs.len():
                let link = module.outputs[x]
                if(link.moduleIndex < 0 or link.pinIndex < 0): continue
                let destPosX = link.moduleIndex mod 16
                let destPosY = link.moduleIndex div 16
                let p1 = ImVec2(x: WIN_PAD - scrollPoint.x + CELL_SIZE_X * j.float32 + winPos.x + CELL_SIZE_X - 24, y: WIN_PAD - scrollPoint.y + CELL_SIZE_Y * (i.float32) + winPos.y + 60 + x.float32 * BUTTON_SIZE_Y) 
                let p2 = ImVec2(x: WIN_PAD - scrollPoint.x + CELL_SIZE_X * destPosX.float32 + winPos.x + WIN_PAD + 4, y: WIN_PAD - scrollPoint.y + CELL_SIZE_Y * destPosY.float32 + winPos.y + 60 + link.pinIndex.float32 * BUTTON_SIZE_Y) 
                # let p3 = p2 / p1
                let halfX = (p2.x - p1.x) / 2

                if(p1.x < p2.x):
                    dl.addBezierCubic(p1, p1 + ImVec2(x: halfX, y: 0), p2 + ImVec2(x: -halfX, y: 0), p2, 0x7F_00_FF_FF.uint32, 4)
                else:
                    dl.addBezierCubic(p1, p1 + ImVec2(x: -halfX, y: 0), p2 + ImVec2(x: halfX, y: 0), p2, 0x7F_00_FF_FF.uint32, 4)
                # dl.addBezierQuadratic(p1, p2, p3, ))

    # draw temporary link
    if(selectedLink.moduleIndex > -1 and selectedLink.pinIndex > -1):
        let destPosX = selectedLink.moduleIndex mod 16
        let destPosY = selectedLink.moduleIndex div 16
        let p1 = ImVec2(x: WIN_PAD - scrollPoint.x + CELL_SIZE_X * destPosX.float32 + winPos.x + CELL_SIZE_X - 24, y: WIN_PAD - scrollPoint.y + CELL_SIZE_Y * destPosY.float32 + winPos.y + 60 + selectedLink.pinIndex.float32 * BUTTON_SIZE_Y) 
        var p2 = ImVec2()
        igGetMousePosNonUDT(p2.addr)
        let halfX = (p2.x - p1.x) / 2

        if(p1.x < p2.x):
            dl.addBezierCubic(p1, p1 + ImVec2(x: halfX, y: 0), p2 + ImVec2(x: -halfX, y: 0), p2, 0x7F_FF_00_00.uint32, 4)
        else:
            dl.addBezierCubic(p1, p1 + ImVec2(x: -halfX, y: 0), p2 + ImVec2(x: halfX, y: 0), p2, 0x7F_FF_00_00.uint32, 4)

        if(igIsMouseDoubleClicked(ImGuiMouseButton.Left)):
            selectedLink.moduleIndex = -1
            selectedLink.pinIndex = -1
    
