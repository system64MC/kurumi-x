import module
import ../../../common/globals
import ../../../common/utils
import ../../../common/synthInfos
type
    BinaryModule* = ref object of SynthModule
        mode*: int32 = 0

    OrModule* = ref object of BinaryModule
    XorModule* = ref object of BinaryModule
    AndModule* = ref object of BinaryModule
            

proc constructOrModule*(): OrModule = 
    var module = new OrModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc constructXorModule*(): XorModule = 
    var module = new XorModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)]
    return module

proc constructAndModule*(): AndModule = 
    var module = new AndModule
    module.outputs = @[
        Link(moduleIndex: -1, pinIndex: -1)]
    module.inputs = @[
        Link(moduleIndex: -1, pinIndex: -1),
        Link(moduleIndex: -1, pinIndex: -1)]
    return module

method synthesize*(module: OrModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var moduleA: SynthModule = nil
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]
    
    if(moduleA == nil and moduleB == nil): return 0

    case module.mode:
    of 0: # 32-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let res = aInt or bInt
        return ((res.uint32 + 0x7F_FF_FF_FF).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0

    of 1: # 32-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF_FF_FF.float).int32
        let bInt = (b * 0x7F_FF_FF_FF.float).int32
        let res = aInt or bInt
        return (res.float / 0x7F_FF_FF_FF.float)
    
    of 2: # 32-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let res = aInt or bInt
        return ((res).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0

    of 3: # 16-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let res = aInt or bInt
        return ((res.uint32 + 0x7F_FF).float / ((0xFF_FF).float64 / 2.0)) - 1.0
    
    of 4: # 16-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF.float).int32
        let bInt = (b * 0x7F_FF.float).int32
        let res = aInt or bInt
        return (res.float / 0x7F_FF.float)
    
    of 5: # 16-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let res = aInt or bInt
        return ((res).float / ((0xFF_FF).float64 / 2.0)) - 1.0

    else: return 0.0

method synthesize*(module: XorModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var moduleA: SynthModule = nil
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]
    
    if(moduleA == nil and moduleB == nil): return 0

    case module.mode:
    of 0: # 32-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let res = aInt xor bInt
        return ((res.uint32 + 0x7F_FF_FF_FF).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0
    
    of 1: # 32-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF_FF_FF.float).int32
        let bInt = (b * 0x7F_FF_FF_FF.float).int32
        let res = aInt xor bInt
        return (res.float / 0x7F_FF_FF_FF.float)
    
    of 2: # 32-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let res = aInt xor bInt
        return ((res).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0

    of 3: # 16-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let res = aInt xor bInt
        return ((res.uint32 + 0x7F_FF).float / ((0xFF_FF).float64 / 2.0)) - 1.0
    
    of 4: # 16-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF.float).int32
        let bInt = (b * 0x7F_FF.float).int32
        let res = aInt xor bInt
        return (res.float / 0x7F_FF.float)
    
    of 5: # 16-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let res = aInt xor bInt
        return ((res).float / ((0xFF_FF).float64 / 2.0)) - 1.0

    else: return 0.0

method synthesize*(module: AndModule, x: float64, pin: int, moduleList: array[256, SynthModule], synthInfos: SynthInfos): float64 =
    var moduleA: SynthModule = nil
    var moduleB: SynthModule = nil

    if(module.inputs[0].moduleIndex > -1):
        moduleA = moduleList[module.inputs[0].moduleIndex]
    if(module.inputs[1].moduleIndex > -1):
        moduleB = moduleList[module.inputs[1].moduleIndex]
    
    if(moduleA == nil and moduleB == nil): return 0

    case module.mode:
    of 0: # 32-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32 - 0x7F_FF_FF_FF).int32
        let res = aInt and bInt
        return ((res.uint32 + 0x7F_FF_FF_FF).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0
    
    of 1: # 32-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF_FF_FF.float).int32
        let bInt = (b * 0x7F_FF_FF_FF.float).int32
        let res = aInt and bInt
        return (res.float / 0x7F_FF_FF_FF.float)
    
    of 2: # 32-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF_FF_FF).float64 / 2.0)).uint32)
        let res = aInt and bInt
        return ((res).float / ((0xFF_FF_FF_FF).float64 / 2.0)) - 1.0

    of 3: # 16-bits, signed
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32 - 0x7F_FF).int32
        let res = aInt and bInt
        return ((res.uint32 + 0x7F_FF).float / ((0xFF_FF).float64 / 2.0)) - 1.0
    
    of 4: # 16-bits, signed 2
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (a * 0x7F_FF.float).int32
        let bInt = (b * 0x7F_FF.float).int32
        let res = aInt or bInt
        return (res.float / 0x7F_FF.float)

    of 5: # 16-bits, unsigned
        let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos) else: 0.0
        let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos) else: 0.0

        let aInt = (((a + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let bInt = (((b + 1.0) * ((0xFF_FF).float64 / 2.0)).uint32)
        let res = aInt and bInt
        return ((res).float / ((0xFF_FF).float64 / 2.0)) - 1.0

    else: return 0.0

import ../serializationObject
import flatty

method serialize*(module: OrModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.OR, data: toFlatty(module))

method serialize*(module: XorModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.XOR, data: toFlatty(module))

method serialize*(module: AndModule): ModuleSerializationObject =
    return ModuleSerializationObject(mType: ModuleType.AND, data: toFlatty(module))