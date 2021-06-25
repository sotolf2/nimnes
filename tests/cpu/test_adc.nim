import ../../cpu.nim


# test normal adc without any overflows
var t_cpu = newCpu()
var test_program = "a9 0a 69 01 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 11
# carry flag not set
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8

# carry and overflow flag tests
test_program = "a9 50 69 10 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x60
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V

test_program = "a9 50 69 50 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xa0
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x40'u8 # V

test_program = "a9 50 69 90 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xe0
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V

test_program = "a9 50 69 d0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x20
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V

test_program = "a9 d0 69 10 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xe0
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V

test_program = "a9 d0 69 50 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x20
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V

test_program = "a9 d0 69 90 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0x60
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x40'u8 # V

test_program = "a9 d0 69 d0 00"
t_cpu.load_and_run(test_program)
doAssert t_cpu.register_a == 0xa0
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V
# test adc with unsigned overflow
test_program = "a9 ff 69 01 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0
doAssert (t_cpu.status and 0x01'u8) == 0x01'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8 # V
doAssert (t_cpu.status and 0x02'u8) == 0x02'u8 # Z

# test adc set carry flag
test_program = "a9 7f 69 01 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x80
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8 # C
doAssert (t_cpu.status and 0x40'u8) == 0x40'u8 # V

# test adc use carry flag
test_program = "a9 7f 69 01 69 01 00"

t_cpu.load_and_run(test_program)

doAssert t_cpu.register_a == 0x81
doAssert (t_cpu.status and 0x01'u8) == 0x00'u8
doAssert (t_cpu.status and 0x40'u8) == 0x00'u8
