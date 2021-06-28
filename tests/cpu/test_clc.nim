import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 01 e8 69 10 90 fb 18 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x10
doAssert t_cpu.register_a == 0x01
doAssert (t_cpu.status and 0x80'u8) == 0x00'u8
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8
