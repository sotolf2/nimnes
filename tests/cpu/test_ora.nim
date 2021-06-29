import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 69 09 96 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0xff
