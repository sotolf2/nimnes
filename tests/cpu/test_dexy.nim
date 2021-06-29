import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "ca 88 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0xff
doAssert t_cpu.register_y == 0xff
doAssert (t_cpu.status and 0x80) == 0x80
