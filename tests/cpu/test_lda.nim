import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 05 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x05
doAssert (t_cpu.status and 0x02) == 0x00
doAssert (t_cpu.status and 0x80) == 0x00

# test 0xa9 lda zero flag

t_cpu = newCpu()
let test_program_0_flag = "a9 00 00"
t_cpu.load_and_run(test_program_0_flag)
doAssert t_cpu.register_a == 0x00
doAssert (t_cpu.status and 0x02'u8) == 0x02'u8
