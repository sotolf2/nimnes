import ../../cpu.nim

var t_cpu = newCpu()
let test_program = "20 09 80 20 0c 80 20 12 80 a2 00 60 e8 e0 05 d0 fb 60 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x00
doAssert t_cpu.register_x == 0x05
doAssert (t_cpu.status and 0x01) == 0x01
doAssert (t_cpu.status and 0x02) == 0x02
doAssert (t_cpu.status and 0x80) == 0x00
