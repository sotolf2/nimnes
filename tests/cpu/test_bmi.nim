import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 fe e8 69 01 30 fb 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x02
doAssert t_cpu.register_a == 0x0
doAssert (t_cpu.status and 0x80'u8) == 0x00'u8
