import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 06 8d 10 00 a9 0a 4d 10 00 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x0c
doAssert t_cpu.mem_read(0x10) == 0x06
