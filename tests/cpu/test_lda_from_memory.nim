import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
t_cpu.mem_write(0x10'u16, 0x55'u8)
let test_program = "a5 10 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x55'u8
