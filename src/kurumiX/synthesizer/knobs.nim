import imgui
import math

const IMGUIKNOBS_PI = 3.14159265358979323846f

proc drawArc1(center: ImVec2, radius, startAngle, endAngle, thickness: float32, color: uint32, numSegments: int32) =
    let
        start = ImVec2(x: center.x + cos(startAngle) * radius, y: center.y + sin(startAngle) * radius)
        myEnd = ImVec2(x: center.x + cos(endAngle) * radius, y: center.y + sin(endAngle) * radius)

        # Calculate bezier arc points
        ax: float32 = start.x - center.x
        ay: float32 = start.y - center.y
        bx: float32 = myEnd.x - center.x
        by: float32 = myEnd.y - center.y
        q1: float32 = ax * ax + ay * ay
        q2: float32 = q1 + ax * bx + ay * by
        k2: float32 = (4.0f / 3.0f) * (sqrt((2.0f * q1 * q2)) - q2) / (ax * by - ay * bx)
        arc1: ImVec2 = ImVec2(x: center.x + ax - k2 * ay, y: center.y + ay + k2 * ax)
        arc2: ImVec2 = ImVec2(x: center.x + bx + k2 * by, y: center.y + by - k2 * bx)

        dl = igGetWindowDrawList()
    
    dl.addBezierCubic(start, arc1, arc2, myEnd, color, thickness, numSegments)

proc drawArc(center: ImVec2, radius, startAngle, endAngle, thickness: float32, color: uint32, numSegments: int32, bezierCount: int32) =
    let
        overlap = thickness * radius * 0.00001f * IMGUIKNOBS_PI
        delta = end_angle - startAngle
        bezStep = 1.0f / bezierCount.float32
    var
        midAngle = startAngle + overlap

    for i in 0..<(bezierCount - 1):
        let midAngle2 = delta * bezStep + midAngle
        drawArc1(center, radius, midAngle - overlap, midAngle2 + overlap, thickness, color, numSegments)
        midAngle = midAngle2

    drawArc1(center, radius, midAngle - overlap, endAngle + overlap, thickness, color, numSegments)
    