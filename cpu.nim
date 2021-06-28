import strutils, strformat, tables

type AddressingMode = enum
  Immediate,
  ZeroPage,
  ZeroPageX,
  ZeroPageY,
  Absolute,
  AbsoluteX,
  AbsoluteY,
  IndirectX,
  IndirectY,
  NoneAddressing

type CPU* = ref object
  register_a*: uint8
  register_x*: uint8
  register_y*: uint8
  status*: uint8 #NV-BDIZC
  program_counter*: uint16
  stack_pointer*: uint8
  memory*: array[0xFFFF,uint8]

type Opcode = object
  opcode: uint8
  name: string
  procedure: proc(self:CPU, mode: AddressingMode)
  bytes: uint16
  cycles: int
  mode: AddressingMode

proc new_opcode(opcode: uint8, name: string, procedure: proc(self: CPU, mode: AddressingMode), bytes: uint16, cycles: int, mode: AddressingMode): Opcode =
  result.opcode = opcode
  result.name = name
  result.procedure = procedure
  result.bytes = bytes
  result.cycles = cycles
  result.mode = mode


proc wrapping_add(self: uint8, other: uint8): uint8 =
  if 0xff - other >= self:
    return self + other
  else:
    return self - (0xff - other)

proc wrapping_add(self: uint16, other: uint16): uint16 =
  if 0xffff - other >= self:
    return self + other
  else:
    return self - (0xffff - other)

proc newCPU*(): CPU =
  result = new CPU

proc mem_read*(self: CPU, address: uint16): uint8 =
  self.memory[address]

proc mem_write*(self: CPU, address: uint16, data: uint8) =
  self.memory[address] = data 

proc mem_read_uint16(self: CPU, pos: uint16): uint16 =
  let lo = self.mem_read(pos).uint16
  let hi = self.mem_read(pos+1).uint16
  (hi shl 8) or (lo)

proc mem_write_uint16(self: CPU, pos: uint16, data: uint16) =
  let hi = (data shr 8).uint8
  let lo = (data and 0xff).uint8
  self.mem_write(pos, lo)
  self.mem_write(pos + 1, hi)

proc get_operand_address(self: CPU, mode: AddressingMode): uint16 =
  case mode
  of Immediate:
    return self.program_counter
  of ZeroPage:
    return self.mem_read(self.program_counter).uint16
  of Absolute:
    return self.mem_read_uint16(self.program_counter)
  of ZeroPageX:
    let pos = self.mem_read(self.program_counter)
    let adr = pos.wrapping_add(self.register_x).uint16
    return adr
  of ZeroPageY:
    let pos = self.mem_read(self.program_counter)
    let adr = pos.wrapping_add(self.register_y).uint16
    return adr
  of AbsoluteX:
    let base = self.mem_read_uint16(self.program_counter)
    let adr = base.wrapping_add(self.register_x.uint16).uint16
    return adr
  of AbsoluteY:
    let base = self.mem_read_uint16(self.program_counter)
    let adr = base.wrapping_add(self.register_y).uint16
    return adr
  of IndirectX:
    let base = self.mem_read_uint16(self.program_counter)
    let pt = base.uint8.wrapping_add(self.register_x)
    let lo = self.mem_read(pt.uint16).uint16
    let hi = self.mem_read(pt.wrapping_add(1).uint16).uint16
    return (hi shl 8) or lo
  of IndirectY:
    let base = self.mem_read_uint16(self.program_counter)
    let lo = self.mem_read(base.uint16).uint16
    let hi = self.mem_read(base.wrapping_add(1).uint16).uint16
    let deref_base = (hi shl 8) or lo
    let deref = deref_base.wrapping_add(self.register_y.uint16)
    return deref
  of NoneAddressing:
    echo "error in get operand address"

proc reset*(self: CPU) =
  self.register_a = 0
  self.register_x = 0
  self.status = 0x20
  self.stack_pointer = 0xff
  self.program_counter = 0
  self.program_counter = self.mem_read_uint16(0xFFFC)

proc load*(self: CPU, program: seq[uint8]) =
  self.program_counter = 0x8000
  for token in program:
    self.memory[self.program_counter] = token
    self.program_counter += 1
  self.mem_write_uint16(0xFFFC, 0x8000)

proc update_zero_and_negative_flags(self: CPU, res: uint8) =
  if res == 0:
    self.status = (self.status or 0x2)
  else:
    self.status = (self.status and 0xfd)

  if (res and 0x80) != 0:
    self.status = (self.status or 0x80)
  else:
    self.status = (self.status and 0x7f)

proc branch_relative(self: CPU, offset: uint8) =
  # if value is negative jump backwards
  # compensate for the current instruction
  self.program_counter -= 1
  if (offset and 0x80'u8) == 0x80'u8:
    #echo fmt"value is negative {value:x}"
    let untwos_complent = (not offset) - 1
    #echo fmt"untwo's complement {untwos_complent}"
    self.program_counter -= untwos_complent
    #compensate for the addition we do after running an instruction
    self.program_counter -= 1
  else:
    self.program_counter += offset
    #compensate for addition after instruction
    self.program_counter -= 1

proc lda(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)

  self.register_a = value
  self.update_zero_and_negative_flags(self.register_a)

proc sta(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  self.mem_write(adr, self.register_a)

proc stx(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  self.mem_write(adr, self.register_x)

proc sty(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  self.mem_write(adr, self.register_y)

proc cmp(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)
  let result = self.register_a - value

  # set C if A >= result
  if self.register_a >= value:
    self.status = (self.status or 0x01)
  else:
    self.status = (self.status and 0xfe)

  # set Z if A == result
  if self.register_a == value:
    self.status = (self.status or 0x02)
  else:
    self.status = (self.status and 0xfd)

  # set N if result is negative
  if (result and 0x80) == 0x80:
    self.status = (self.status or 0x80)
  else:
    self.status = (self.status and 0xef)

proc cpx(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)
  let result = self.register_x - value

  # set C if A >= result
  if self.register_x >= value:
    self.status = (self.status or 0x01)
  else:
    self.status = (self.status and 0xfe)

  # set Z if A == result
  if self.register_x == value:
    self.status = (self.status or 0x02)
  else:
    self.status = (self.status and 0xfd)

  # set N if result is negative
  if (result and 0x80) == 0x80:
    self.status = (self.status or 0x80)
  else:
    self.status = (self.status and 0xef)


proc cpy(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)
  let result = self.register_y - value

  # set C if A >= result
  if self.register_y >= value:
    self.status = (self.status or 0x01)
  else:
    self.status = (self.status and 0xfe)

  # set Z if A == result
  if self.register_y == value:
    self.status = (self.status or 0x02)
  else:
    self.status = (self.status and 0xfd)

  # set N if result is negative
  if (result and 0x80) == 0x80:
    self.status = (self.status or 0x80)
  else:
    self.status = (self.status and 0xef)

proc op_and(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)

  self.register_a = (self.register_a and value)
  self.update_zero_and_negative_flags(self.register_a)

proc asl(self: CPU, mode: AddressingMode) =
  if mode == AddressingMode.NoneAddressing:
    let value = self.register_a
    self.register_a = (self.register_a shl 1'u8)
    self.update_zero_and_negative_flags(self.register_a)

    #set carry flag
    if (value and 0x80'u8) == 0x80'u8:
      self.status = (self.status or 0x1'u8)
    else:
      self.status = (self.status and 0xfe'u8)
  else:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    let result: uint8 = (value shl 1)
    self.mem_write(adr, result)

    #set carry flag
    if (value and 0x80'u8) == 0x80'u8:
      self.status = (self.status or 0x01'u8)
    else:
      self.status = (self.status and 0xfe'u8)
    #set negative flag (no setting zero flag here since we don't muck with the register
    if (result and 0x80'u8) == 0x80'u8:
      self.status = (self.status or 0x80'u8)
    else:
      self.status = (self.status and 0x7f'u8)

proc bcc(self: CPU, mode: AddressingMode) =
  if (self.status and 0x1) == 0x0'u8:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    #echo fmt"bcc value: {value:x}"
    self.branch_relative(value)

proc bcs(self: CPU, mode: AddressingMode) =
  if (self.status and 0x01) == 0x01:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    #echo fmt"bcc value: {value:x}"
    self.branch_relative(value)
    
proc beq(self: CPU, mode: AddressingMode) =
  if (self.status and 0x02) == 0x02:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    #echo fmt"bcc value: {value:x}"
    self.branch_relative(value)

proc bne(self: CPU, mode: AddressingMode) =
  if (self.status and 0x02) == 0x00:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    #echo fmt"bcc value: {value:x}"
    self.branch_relative(value)

proc bmi(self: CPU, mode: AddressingMode) =
  if (self.status and 0x80) == 0x80:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    self.branch_relative(value)

proc bpl(self: CPU, mode: AddressingMode) =
  if (self.status and 0x80) == 0x00:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    self.branch_relative(value)

proc bvc(self: CPU, mode: AddressingMode) =
  if (self.status and 0x40) == 0x00:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    self.branch_relative(value)

proc bvs(self: CPU, mode: AddressingMode) =
  if (self.status and 0x40) == 0x40:
    let adr = self.get_operand_address(mode)
    let value = self.mem_read(adr)
    self.branch_relative(value)

proc bit(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value = self.mem_read(adr)

  # set z flag if value & reg_a == 0
  if (value and self.register_a) == 0:
    self.status = (self.status or 0x02)
  else:
    self.status = (self.status and 0xfd)
  # set overflow to 6th bit of mem value
  if (value and 0x20) == 1:
    self.status = (self.status or 0x40)
  else:
    self.status = (self.status and 0xbf)
  # set negative to bit 7 of memory value
  if (value and 0x40) == 1:
    self.status = (self.status or 0x80)
  else:
    self.status = (self.status and 0x7f)


proc tax(self: CPU, mode: AddressingMode) =
  self.register_x = self.register_a
  self.update_zero_and_negative_flags(self.register_x)

proc tay(self: CPU, mode: AddressingMode) =
  self.register_y = self.register_a
  self.update_zero_and_negative_flags(self.register_y)

proc tsx(self: CPU, mode: AddressingMode) =
  self.register_x = self.stack_pointer
  self.update_zero_and_negative_flags(self.register_x)

proc txa(self: CPU, mode: AddressingMode) =
  self.register_a = self.register_x
  self.update_zero_and_negative_flags(self.register_a)

proc txs(self: CPU, mode: AddressingMode) =
  self.stack_pointer = self.register_x
  self.update_zero_and_negative_flags(self.register_x)

proc tya(self: CPU, mode: AddressingMode) =
  self.register_a = self.register_y
  self.update_zero_and_negative_flags(self.register_a)

proc inx(self: CPU, mode: AddressingMode) =
  if self.register_x == 0xff:
    self.register_x = 0x00
  else:
    self.register_x += 1
  self.update_zero_and_negative_flags(self.register_x)

proc sec(self: CPU, mode: AddressingMode) =
  self.status = (self.status or 0x01'u8)

proc clc(self: CPU, mode: AddressingMode) =
  self.status = (self.status and 0xfe)

proc cld(self: CPU, mode: AddressingMode) =
  self.status = (self.status and 0xf7)

proc cli(self: CPU, mode: AddressingMode) =
  self.status = (self.status and 0xfb)

proc clv(self: CPU, mode: AddressingMode) =
  self.status = (self.status and 0xbf)

{.push overflowChecks: off.}
proc adc(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value: uint8 = self.mem_read(adr)
  var carry: uint8 = (if (self.status and 0x01) != 0: 1 else: 0)
  let accumulator: uint8 = self.register_a
  self.register_a = accumulator + value + carry
  
  self.update_zero_and_negative_flags(self.register_a)
  # set overflow
  if ((accumulator xor self.register_a) and (value xor self.register_a) and 0x80'u8) != 0x00'u8:
    self.status = (self.status or 0x40)
  else:
    self.status = (self.status and 0xbf)
  # set carry flag
  if self.register_a < accumulator:
    self.status = (self.status or 0x01)
  else:
    self.status = (self.status and 0xfe)


proc sbc(self: CPU, mode: AddressingMode) =
  let adr = self.get_operand_address(mode)
  let value: uint8 = self.mem_read(adr)
  let two_complement = (not value) + 1
  var carry: uint8 = (if (self.status and 0x01) != 0: 0 else: 1)
  let accumulator: uint8 = self.register_a
  self.register_a = accumulator + two_complement - carry
  
  self.update_zero_and_negative_flags(self.register_a)
  # set overflow flag
  if ((accumulator xor self.register_a) and (two_complement xor self.register_a) and 0x80'u8) != 0x00'u8:
    self.status = (self.status or 0x40)
  else:
    self.status = (self.status and 0xbf)
  # set overflow flag
  if self.register_a < accumulator:
    self.status = (self.status or 0x01)
  else:
    self.status = (self.status and 0xfe)

{.pop.}

proc brk(self: CPU, mode: AddressingMode) =
  discard

proc build_opcode_table(): Table[uint8, Opcode] =
  var opcodes: Table[uint8, Opcode]
  opcodes[0x00] = new_opcode(0x00, "brk", brk, 1, 7, AddressingMode.NoneAddressing)
  opcodes[0xaa] = new_opcode(0xaa, "tax", tax, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xe8] = new_opcode(0xe8, "inx", inx, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xa9] = new_opcode(0xa9, "lda", lda, 2, 2, AddressingMode.Immediate)
  opcodes[0xa5] = new_opcode(0xa5, "lda", lda, 2, 3, AddressingMode.ZeroPage)
  opcodes[0xb5] = new_opcode(0xb5, "lda", lda, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0xad] = new_opcode(0xad, "lda", lda, 3, 4, AddressingMode.Absolute)
  opcodes[0xbd] = new_opcode(0xbd, "lda", lda, 3, 4, AddressingMode.AbsoluteX) # +1 if page crossed
  opcodes[0xb9] = new_opcode(0xb9, "lda", lda, 3, 4, AddressingMode.AbsoluteY) # +1 if page crossed
  opcodes[0xa1] = new_opcode(0xa1, "lda", lda, 2, 6, AddressingMode.IndirectX)
  opcodes[0xb1] = new_opcode(0xb1, "lda", lda, 2, 5, AddressingMode.IndirectY) # +1 if page crossed
  opcodes[0x69] = new_opcode(0x69, "adc", adc, 2, 2, AddressingMode.Immediate)
  opcodes[0x65] = new_opcode(0x65, "adc", adc, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x75] = new_opcode(0x75, "adc", adc, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0x6d] = new_opcode(0x6d, "adc", adc, 3, 4, AddressingMode.Absolute)
  opcodes[0x7d] = new_opcode(0x7d, "adc", adc, 3, 4, AddressingMode.AbsoluteX) # +1 if page crossed
  opcodes[0x79] = new_opcode(0x79, "adc", adc, 3, 4, AddressingMode.AbsoluteY) # +1 if page crossed
  opcodes[0x61] = new_opcode(0x61, "adc", adc, 2, 6, AddressingMode.IndirectX)
  opcodes[0x71] = new_opcode(0x71, "adc", adc, 2, 5, AddressingMode.IndirectY) # +1 if page crossed
  opcodes[0xe9] = new_opcode(0xe9, "sbc", sbc, 2, 2, AddressingMode.Immediate)
  opcodes[0xe5] = new_opcode(0xe5, "sbc", sbc, 2, 3, AddressingMode.ZeroPage)
  opcodes[0xf5] = new_opcode(0xf5, "sbc", sbc, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0xed] = new_opcode(0xed, "sbc", sbc, 3, 4, AddressingMode.Absolute)
  opcodes[0xfd] = new_opcode(0xfd, "sbc", sbc, 3, 4, AddressingMode.AbsoluteX) # +1 if page crossed
  opcodes[0xf9] = new_opcode(0xf9, "sbc", sbc, 3, 4, AddressingMode.AbsoluteY) # +1 if page crossed
  opcodes[0xe1] = new_opcode(0xe1, "sbc", sbc, 2, 6, AddressingMode.IndirectX)
  opcodes[0xf1] = new_opcode(0xf1, "sbc", sbc, 2, 5, AddressingMode.IndirectY) # +1 if page crossed
  opcodes[0x38] = new_opcode(0x38, "sec", sec, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x29] = new_opcode(0x29, "and", op_and, 2, 2, AddressingMode.Immediate)
  opcodes[0x25] = new_opcode(0x25, "and", op_and, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x35] = new_opcode(0x35, "and", op_and, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0x2d] = new_opcode(0x2d, "and", op_and, 3, 4, AddressingMode.Absolute)
  opcodes[0x3d] = new_opcode(0x3d, "and", op_and, 3, 4, AddressingMode.AbsoluteX) # +1 if page crossed
  opcodes[0x39] = new_opcode(0x39, "and", op_and, 3, 4, AddressingMode.AbsoluteY) # +1 if page crossed
  opcodes[0x21] = new_opcode(0x21, "and", op_and, 2, 6, AddressingMode.IndirectX) 
  opcodes[0x31] = new_opcode(0x31, "and", op_and, 2, 5, AddressingMode.IndirectY) # +1 if page crossed
  opcodes[0x0a] = new_opcode(0x0a, "asl", asl, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x06] = new_opcode(0x06, "asl", asl, 1, 2, AddressingMode.ZeroPage)
  opcodes[0x16] = new_opcode(0x16, "asl", asl, 1, 2, AddressingMode.ZeroPageX)
  opcodes[0x0e] = new_opcode(0x0e, "asl", asl, 1, 2, AddressingMode.Absolute)
  opcodes[0x1e] = new_opcode(0x1e, "asl", asl, 1, 2, AddressingMode.AbsoluteX)
  opcodes[0x90] = new_opcode(0x90, "bcc", bcc, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0xb0] = new_opcode(0xb0, "bcs", bcs, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0xf0] = new_opcode(0xf0, "beq", beq, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0x24] = new_opcode(0x24, "bit", bit, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x2c] = new_opcode(0x2c, "bit", bit, 3, 4, AddressingMode.Absolute)
  opcodes[0x30] = new_opcode(0x30, "bmi", bmi, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0xd0] = new_opcode(0xd0, "bne", bne, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0x10] = new_opcode(0x10, "bpl", bpl, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0x50] = new_opcode(0x50, "bvc", bvc, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0x70] = new_opcode(0x70, "bvs", bvs, 2, 2, AddressingMode.Immediate) # +1 if branch succeeds +2 if to a new page
  opcodes[0x18] = new_opcode(0x18, "clc", clc, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xd8] = new_opcode(0xd8, "cld", cld, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x58] = new_opcode(0x58, "cli", cli, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xb8] = new_opcode(0xb8, "clv", clv, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xc9] = new_opcode(0xc9, "cmp", cmp, 2, 2, AddressingMode.Immediate)
  opcodes[0xc5] = new_opcode(0xc5, "cmp", cmp, 2, 3, AddressingMode.ZeroPage)
  opcodes[0xd5] = new_opcode(0xd5, "cmp", cmp, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0xcd] = new_opcode(0xcd, "cmp", cmp, 3, 4, AddressingMode.Absolute)
  opcodes[0xdd] = new_opcode(0xdd, "cmp", cmp, 3, 4, AddressingMode.AbsoluteX) # +1 if page crossed
  opcodes[0xd9] = new_opcode(0xd9, "cmp", cmp, 3, 4, AddressingMode.AbsoluteY) # +1 if page crossed
  opcodes[0xc1] = new_opcode(0xc1, "cmp", cmp, 2, 6, AddressingMode.IndirectX)
  opcodes[0xd1] = new_opcode(0xd1, "cmp", cmp, 2, 5, AddressingMode.IndirectY) # +1 if page crossed
  opcodes[0xe0] = new_opcode(0xe0, "cpx", cpx, 2, 2, AddressingMode.Immediate)
  opcodes[0xe4] = new_opcode(0xe4, "cpx", cpx, 2, 3, AddressingMode.ZeroPage)
  opcodes[0xec] = new_opcode(0xec, "cpx", cpx, 3, 5, AddressingMode.Absolute)
  opcodes[0xc0] = new_opcode(0xc0, "cpy", cpy, 2, 2, AddressingMode.Immediate)
  opcodes[0xc4] = new_opcode(0xc4, "cpy", cpy, 2, 3, AddressingMode.ZeroPage)
  opcodes[0xcc] = new_opcode(0xcc, "cpy", cpy, 3, 5, AddressingMode.Absolute)
  opcodes[0x85] = new_opcode(0x85, "sta", sta, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x95] = new_opcode(0x95, "sta", sta, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0x8d] = new_opcode(0x8d, "sta", sta, 3, 4, AddressingMode.Absolute)
  opcodes[0x9d] = new_opcode(0x9d, "sta", sta, 3, 5, AddressingMode.AbsoluteX)
  opcodes[0x99] = new_opcode(0x99, "sta", sta, 3, 5, AddressingMode.AbsoluteY)
  opcodes[0x81] = new_opcode(0x81, "sta", sta, 2, 6, AddressingMode.IndirectX)
  opcodes[0x91] = new_opcode(0x91, "sta", sta, 2, 6, AddressingMode.IndirectY)
  opcodes[0x86] = new_opcode(0x86, "stx", stx, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x96] = new_opcode(0x96, "stx", stx, 2, 4, AddressingMode.ZeroPageY)
  opcodes[0x8e] = new_opcode(0x8e, "stx", stx, 3, 4, AddressingMode.Absolute)
  opcodes[0x84] = new_opcode(0x84, "sty", sty, 2, 3, AddressingMode.ZeroPage)
  opcodes[0x94] = new_opcode(0x94, "sty", sty, 2, 4, AddressingMode.ZeroPageX)
  opcodes[0x8c] = new_opcode(0x8c, "sty", sty, 3, 4, AddressingMode.Absolute)
  opcodes[0xa8] = new_opcode(0xa8, "tay", tay, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0xba] = new_opcode(0xba, "tsx", tsx, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x8a] = new_opcode(0x8a, "txa", txa, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x9a] = new_opcode(0x9a, "txs", txs, 1, 2, AddressingMode.NoneAddressing)
  opcodes[0x98] = new_opcode(0x98, "tya", tya, 1, 2, AddressingMode.NoneAddressing)

  return opcodes

proc run*(self: CPU) =
  let opcodes = build_opcode_table()

  while self.memory[self.program_counter] != 0x00'u8:
    let opcode = self.memory[self.program_counter]
    let inst = opcodes[opcode]
    #echo fmt"pc: {self.program_counter:x} o: {inst.name} a: {self.register_a:x} x: {self.register_x:x} y: {self.register_y:x} s: {self.status:b}"

    self.program_counter += 1
    inst.procedure(self, inst.mode)
    self.program_counter += (inst.bytes - 1)

  #echo fmt"pc: {self.program_counter:x} o: {self.memory[self.program_counter]:x} a: {self.register_a:x} x: {self.register_x:x} y: {self.register_y:x} s: {self.status:b}"

proc load_and_run*(self: CPU, program: seq[uint8]) =
  self.load(program)
  self.reset()
  self.run()

proc load_and_run*(self: CPU, program: string) =
  var prog = program.split()
  var bytecode: seq[uint8]
  for token in prog:
    bytecode.add(token.parseHexInt().uint8)

  self.load_and_run(bytecode)
  
