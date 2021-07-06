import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 55 85 10 a9 00 a5 10 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x55'u8
