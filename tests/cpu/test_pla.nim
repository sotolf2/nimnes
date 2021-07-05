import ../../cpu.nim


# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 aa 48 a9 00 68 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0xaa
doAssert (t_cpu.status and 0x02) == 0x00
doAssert (t_cpu.status and 0x80) == 0x80
