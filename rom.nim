
type Mirroring* = enum
  Vertical,
  Horizontal,
  FourScreen

type Rom* = object
  prg_rom*: seq[uint8]
  chr_rom*: seq[uint8]
  mapper*: uint8
  screen_mirroring*: Mirroring

proc new_rom_from_seq*(raw_data: seq[uint8]): Rom =
  result.prg_rom = raw_data
