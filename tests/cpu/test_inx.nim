import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 0a aa e8 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 11
