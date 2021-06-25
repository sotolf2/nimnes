import ../../cpu.nim

#test sec
var t_cpu = newCpu()
let test_program = "38 00"

t_cpu.load_and_run(test_program)

doAssert (t_cpu.status and 0x01'u8) == 0x01 # C
