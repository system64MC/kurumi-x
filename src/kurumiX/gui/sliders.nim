import imgui

proc igSliderScalar2(label: cstring, data_type: ImGuiDataType, p_data: pointer, p_min: pointer, p_max: pointer, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool {.importc: "igSliderScalar".}

proc sliderF64*(label: cstring, data: ptr float64, min: float64, max: float64, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.Double, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderF32*(label: cstring, data: ptr float32, min: float32, max: float32, format: cstring = "%.3f", flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderFloat(label, data, min, max, format, flags)

proc sliderS64*(label: cstring, data: ptr int64, min: int64, max: int64, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.S64, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderS32*(label: cstring, data: ptr int32, min: int32, max: int32, format: cstring = "%d", flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderInt(label, data, min, max, format, flags)

proc sliderS16*(label: cstring, data: ptr int16, min: int16, max: int16, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.S16, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderS8*(label: cstring, data: ptr int8, min: int8, max: int8, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.S8, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderU64*(label: cstring, data: ptr uint64, min: uint64, max: uint64, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.U64, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderU32*(label: cstring, data: ptr uint32, min: uint32, max: uint32, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.U32, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderU16*(label: cstring, data: ptr uint16, min: uint16, max: uint16, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.U16, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

proc sliderU8*(label: cstring, data: ptr uint8, min: uint8, max: uint8, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
  return igSliderScalar2(label, ImGuiDataType.U8, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

# proc sliderBool*(label: cstring, data: ptr bool, format: cstring = nil, flags: ImGuiSliderFlags = 0.ImGuiSliderFlags): bool =
#   let min = 0
#   let max = 1
#   return igSliderScalar2(label, ImGuiDataType.U8, cast[pointer](data), cast[pointer](addr min), cast[pointer](addr max), format, flags)

