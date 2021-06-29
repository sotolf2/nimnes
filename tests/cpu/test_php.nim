import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 00 08 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.mem_read(0x01ff) == 0x22
doAssert t_cpu.stack_pointer == 0xfe
