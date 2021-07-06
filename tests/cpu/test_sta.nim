import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 15 8d 10 00 a9 00 ad 10 00 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.mem_read(0x10) == 0x15
doAssert t_cpu.register_a == 0x15
