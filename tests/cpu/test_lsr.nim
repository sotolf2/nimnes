import ../../cpu.nim


var t_cpu = newCpu()
var test_program = "a9 02 4a 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x01

test_program = "a9 01 4a 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x00
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8

