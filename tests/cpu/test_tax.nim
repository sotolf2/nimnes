import ../../cpu.nim


# test ldx
var t_cpu = newCpu()
let test_program = "a9 0a aa 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 10
