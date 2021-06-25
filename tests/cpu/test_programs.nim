import ../../cpu.nim


# Test 5 ops working together
var t_cpu = newCpu()
let test_program = "a9 c0 aa e8 00"
t_cpu.load_and_run(test_program)

doAssert t_cpu.register_x == 0xc1

# Text inx overflow
t_cpu = newCpu()
let test_overflow_program = "a9 ff aa e8 e8 00"
t_cpu.load_and_run(test_overflow_program)
doAssert t_cpu.register_x == 1
