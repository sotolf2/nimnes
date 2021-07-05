import ../../cpu.nim


var t_cpu = newCpu()
let test_program = "a9 8f 2a 6a 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x8f
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8
doAssert (t_cpu.status and 0x80'u8) == 0x80'u8
