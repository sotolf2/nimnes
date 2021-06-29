import ../../cpu.nim

# test 0xa9 lda immedeate load data
var t_cpu = newCpu()
let test_program = "a9 00 aa a9 11 8d 10 00 a9 80 8d 11 00 a9 05 8d 12 00 e8 8a c9 05 f0 03 6c 10 00 8a 00"
t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x05
