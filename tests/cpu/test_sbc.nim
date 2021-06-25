import ../../cpu.nim


# test normal sdc without any overflows
var t_cpu = newCpu()
var test_program = "a9 0a e9 01 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 08
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

# test sdc 1-1
test_program = "a9 50 e9 f0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x5f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x0'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

test_program = "a9 50 e9 b0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x9f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x0'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x40'u8 # V

test_program = "a9 50 e9 70 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xdf'u8
doAssert (t_cpu.status and 0x01'u8) == 0x0'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

test_program = "a9 50 e9 30 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x1f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

test_program = "a9 d0 e9 f0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xdf'u8
doAssert (t_cpu.status and 0x01'u8) == 0x0'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

test_program = "a9 d0 e9 b0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x1f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V

test_program = "a9 d0 e9 70 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x5f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x40'u8 # V

test_program = "a9 d0 e9 30 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x9f'u8
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x0'u8 # V
