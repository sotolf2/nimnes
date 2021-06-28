import ../../cpu.nim

# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "e8 e0 10 d0 fb 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x10
doAssert (t_cpu.status and 0x02'u8) == 0x02'u8
