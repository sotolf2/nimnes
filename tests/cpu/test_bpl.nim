import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 01 e8 0a 10 fc 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x07
doAssert t_cpu.register_a == 0x80
doAssert (t_cpu.status and 0x80'u8) == 0x80'u8
