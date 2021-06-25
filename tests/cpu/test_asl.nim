import ../../cpu.nim


var t_cpu = newCpu()
var test_program = "a9 01 0a 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x02

test_program = "a9 08 0a 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x10

test_program = "a9 ff 0a 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xfe
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8
