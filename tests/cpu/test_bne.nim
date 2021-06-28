import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 01 e8 0a d0 fc 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x08
doAssert (t_cpu.status and 0x02'u8) == 0x02'u8
