import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 ff e8 0a b0 fc 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0x09
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8
