import srvm_vm
import srvm_core as core

proc test_basic_srvm():
    let vm = srvm_vm.SRVM()
    # Manual bytecode for:
    # ADDI a0, x0, 10  (x10 = 0 + 10)
    # ADDI a1, x0, 32  (x11 = 0 + 32)
    # ADD  a2, a0, a1  (x12 = 10 + 32 = 42)
    # VMSYS VMO_PRINT, a2
    # VMSYS VMO_HALT
    
    # RV32I encoding
    # ADDI: imm[11:0] rs1 000 rd 0010011
    # 000000001010 00000 000 01010 0010011 -> 0x00A00513
    
    # ADDI x11, x0, 32
    # 000000100000 00000 000 01011 0010011 -> 0x02000593
    
    # ADD x12, x10, x11
    # 0000000 01011 01010 000 01100 0110011 -> 0x00B50633
    
    # VMSYS PRINT, x12
    # 0000000 00000 01100 000 00000 1110011 -> 0x00060073
    # Wait, funct7 is VMO_PRINT (9)
    # 0001001 00000 01100 000 00000 1110011 -> 0x12060073
    
    # VMSYS HALT
    # 0000001 00000 00000 000 00000 1110011 -> 0x02000073

    let bytecode = [
        0x13, 0x05, 0xA0, 0x00,
        0x93, 0x05, 0x00, 0x02,
        0x33, 0x06, 0xB5, 0x00,
        0x73, 0x00, 0x06, 0x12,
        0x73, 0x00, 0x00, 0x02
    ]
    
    print "Running SRVM test..."
    vm.run(bytecode)
    print "SRVM result: " + str(vm.state.x[12])

proc test_load_store_srvm():
    let vm = srvm_vm.SRVM()
    # ADDI x10, x0, 100  (Address 100)
    # ADDI x11, x0, 123  (Value 123)
    # SD   x11, 0(x10)   (Store x11 to stack[100])
    # ADDI x11, x0, 0    (Clear x11)
    # LD   x12, 0(x10)   (Load stack[100] to x12)
    # VMSYS PRINT, x12
    # VMSYS HALT
    
    # SD: imm[11:5] rs2 rs1 011 imm[4:0] 0100011
    # 0000000 01011 01010 011 00000 0100011 -> 0x00B53023
    
    # LD: imm[11:0] rs1 011 rd 0000011
    # 000000000000 01010 011 01100 0000011 -> 0x00053603

    let bytecode = [
        0x13, 0x05, 0x40, 0x06, # ADDI x10, x0, 100
        0x93, 0x05, 0xB0, 0x07, # ADDI x11, x0, 123
        0x23, 0x30, 0xB5, 0x00, # SD   x11, 0(x10)
        0x93, 0x05, 0x00, 0x00, # ADDI x11, x0, 0
        0x03, 0x36, 0x05, 0x00, # LD   x12, 0(x10)
        0x73, 0x00, 0x06, 0x12, # VMSYS PRINT, x12
        0x73, 0x00, 0x00, 0x02  # VMSYS HALT
    ]
    
    print "Running SRVM Load/Store test..."
    vm.run(bytecode)
    print "SRVM Load result: " + str(vm.state.x[12])

proc test_ldc_srvm():
    let vm = srvm_vm.SRVM()
    push(vm.state.constants, "Hello RISC-V!")
    push(vm.state.constants, 3.14159)
    
    # LDC a0, 0 (Load "Hello RISC-V!")
    # VMSYS PRINT, a0
    # LDC a1, 1 (Load 3.14159)
    # VMSYS PRINT, a1
    # VMSYS HALT
    
    # LDC: imm[31:12] rd 1011011
    # a0 (x10): 00000000000000000000 01010 1011011 -> 0x0000055B
    # a1 (x11): 00000000000000000001 01011 1011011 -> 0x000015DB

    let bytecode = [
        0x5B, 0x05, 0x00, 0x00, # LDC a0, 0
        0x73, 0x00, 0x05, 0x12, # VMSYS PRINT, a0
        0xDB, 0x15, 0x00, 0x00, # LDC a1, 1
        0x73, 0x80, 0x05, 0x12, # VMSYS PRINT, a1 (rs1=x11)
        0x73, 0x00, 0x00, 0x02  # VMSYS HALT
    ]
    
    print "Running SRVM LDC test..."
    vm.run(bytecode)

proc test_globals_srvm():
    let vm = srvm_vm.SRVM()
    push(vm.state.constants, "my_global")
    
    # ADDI a0, x0, 1337
    # ADDI a1, x0, 0 (index of "my_global")
    # VMSYS OBJ_SET_GLOBAL, a1, a0
    # ADDI a0, x0, 0
    # VMSYS OBJ_GET_GLOBAL, a2, a1
    # VMSYS PRINT, a2
    # VMSYS HALT

    let bytecode = [
        19, 5, 144, 83, # ADDI a0, 1337
        147, 5, 0, 0,   # ADDI a1, 0
        115, 160, 165, 2, # SET_GLOBAL a1, a0
        19, 5, 0, 0,    # ADDI a0, 0
        115, 166, 5, 0, # GET_GLOBAL a2, a1
        115, 0, 6, 18,  # PRINT a2
        115, 0, 0, 2    # HALT
    ]
    
    print "Running SRVM Globals test..."
    vm.run(bytecode)
    print "SRVM Global result: " + str(vm.state.heap["my_global"])

proc test_branch_loop_srvm():
    let vm = srvm_vm.SRVM()
    let bytecode = [
        0x13, 0x05, 0x50, 0x00, # ADDI a0, 5
        0x93, 0x05, 0x10, 0x00, # ADDI a1, 1
        0x73, 0x00, 0x90, 0x00, # PRINT a0 (rs1=9)
        0x33, 0x05, 0xB5, 0x40, # SUB a0, a0, a1
        0xE3, 0x1C, 0x05, 0xFE, # BNE a0, x0, -8
        0x73, 0x00, 0x10, 0x00  # HALT (rs1=1)
    ]
    
    print "Running SRVM Branch/Loop test..."
    vm.run(bytecode)
    print "Branch result: " + str(vm.state.x[10]) # Check a0

proc test_function_call_srvm():
    let vm = srvm_vm.SRVM()
    
    # Chunk 1: Function (Add two numbers)
    # ADDI a0, a0, a1
    # RET (JALR x0, 0(x1))
    let chunk1 = [
        0x33, 0x05, 0xB5, 0x00, # ADD a0, a0, a1
        0x67, 0x00, 0x00, 0x00  # JALR x0, 0(x1)
    ]
    push(vm.state.chunks, []) # Placeholder for chunk 0
    push(vm.state.chunks, chunk1)
    
    # Chunk 0: Main
    # ADDI a0, x0, 20
    # ADDI a1, x0, 22
    # ADDI t0, x0, 1 (chunk index)
    # VMSYS OBJ_NEW_FUNC a2, t0
    # VMSYS VMO_CALL a2
    # VMSYS PRINT a0
    # VMSYS HALT
    
    let main_bc = [
        0x13, 0x05, 0x40, 0x01, # ADDI a0, 20
        0x93, 0x05, 0x60, 0x01, # ADDI a1, 22
        0x13, 0x03, 0x10, 0x00, # ADDI t0, 1
        0x73, 0x06, 0x53, 0x00, # NEW_FUNC a2, t0 (f3=2, f7=5, rd=12, rs1=5)
        0x73, 0x00, 0x26, 0x08, # VMO_CALL a2 (f3=0, f7=4, rs1=12)
        0x73, 0x00, 0x05, 0x12, # PRINT a0
        0x73, 0x00, 0x00, 0x02  # HALT
    ]
    vm.state.chunks[0] = main_bc
    
    print "Running SRVM Function Call test..."
    vm.run(main_bc)

test_basic_srvm()
test_load_store_srvm()
test_ldc_srvm()
test_globals_srvm()
test_branch_loop_srvm()
test_function_call_srvm()
