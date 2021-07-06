import 
  strformat,
  sugar,
  rom

const
  RAM: uint16 = 0x0000
  RAM_MIRRORS_END: uint16 = 0x1FFF
  PPU_REGISTERS: uint16 = 0x2000
  PPU_REGISTERS_MIRRORS_END: uint16 = 0x3FFF
  ROM: uint16 = 0x8000
  ROM_REGISTERS_END: uint16 = 0xFFFF

type Bus* = ref object
  cpu_vram: array[0xFFFF, uint8]
  rom: Rom

proc new_bus*(rom: Rom): Bus =
  result = Bus()
  var empty_ram: array[0xFFFF, uint8]
  result.rom = rom
  result.cpu_vram = empty_ram

proc read_prg_rom(self: Bus, adr: uint16): uint8 =
  var rom_adr = adr - 0x8000
  if self.rom.prg_rom.len() == 0x4000 and rom_adr >= 0x4000:
    # mirror if needed
    rom_adr = rom_adr mod 0x4000
  self.rom.prg_rom[rom_adr]

proc mem_read*(self: Bus, adr: uint16): uint8 =
  case adr
  of RAM..RAM_MIRRORS_END:
    let mirror_down_addr = (adr and 0x07FF)
    return self.cpu_vram[mirror_down_addr]
  of PPU_REGISTERS..PPU_REGISTERS_MIRRORS_END:
    #let mirror_down_addr = (adr and 0x2007)
    echo "PPU not yet supported"
  of ROM..ROM_REGISTERS_END:
    return self.read_prg_rom(adr)
  else:
    echo fmt"Ignoring memory access at {adr:x}"
    
proc mem_write*(self: Bus, adr: uint16, data: uint8) =
  case adr
  of RAM..RAM_MIRRORS_END:
    let mirror_down_addr = (adr and 0xFFFF)
    self.cpu_vram[mirror_down_addr] = data
  of PPU_REGISTERS..PPU_REGISTERS_MIRRORS_END:
    #let mirror_down_addr = (adr and 0x2007)
    echo "PPU not yet supported"
  else:
    echo fmt"Ignoring memory write-access at {adr:x}"
