# # TODO: This is lab1.1
# /* Real Mode Hello World */
# .code16

# .global start
# start:
# 	movw %cs, %ax
# 	movw %ax, %ds
# 	movw %ax, %es
# 	movw %ax, %ss
# 	movw $0x7d00, %ax
# 	movw %ax, %sp # setting stack pointer to 0x7d00
# 	# TODO:
# 	# pushing the size to print into stack
# 	# pushing the address of message into stack

# 	pushw $13 
# 	pushw $message 
# 	callw displayStr 
# loop:
# 	jmp loop

# message:
# 	.string "Hello, World!\n\0"

# displayStr:
#  	pushw %bp
#  	movw 4(%esp), %ax
#  	movw %ax, %bp
# 	# TODO：陷入中断,查阅BIOS中断表
#  	movw 6(%esp), %cx	# 打印的字符串长度
#  	movw $0x1301, %ax	# AH=0x13 打印字符串
#  	movw $0x000c, %bx	# BH=0x00 黑底 BL=0x0c 红字
#  	movw $0x0000, %dx	# 在第0行0列开始打印
#  	int $0x10			# 陷入0x10号中断
#  	popw %bp
#  	ret

# # TODO: This is lab1.2
# /* Protected Mode Hello World */
# .code16

# .global start
# start:
# 	movw %cs, %ax
# 	movw %ax, %ds
# 	movw %ax, %es
# 	movw %ax, %ss
# 	# TODO:关闭中断
# 	cli # clear interuption

# 	# 启动A20总线
# 	inb $0x92, %al 
# 	orb $0x02, %al
# 	outb %al, $0x92

# 	# 加载GDTR
# 	data32 addr32 lgdt gdtDesc # loading gdtr, data32, addr32

# 	# TODO：设置CR0的PE位（第0位）为1
# 	movl %cr0, %eax
# 	orb $0x01, %al
# 	movl %eax, %cr0 # setting cr0

# 	# 长跳转切换至保护模式
# 	data32 ljmp $0x08, $start32 # reload code segment selector and ljmp to start32, data32

# .code32
# start32:
# 	movw $0x10, %ax # setting data segment selector
# 	movw %ax, %ds
# 	movw %ax, %es
# 	movw %ax, %fs
# 	movw %ax, %ss
# 	movw $0x18, %ax # setting graphics data segment selector
# 	movw %ax, %gs
	
# 	movl $0x8000, %eax # setting esp
# 	movl %eax, %esp
# 	# TODO:
# 	# 输出Hello World，参考app/app.s
# 	pushl $13
# 	pushl $message
# 	calll displayStr
# loop32:
# 	jmp loop32

# message:
# 	.string "Hello, World!\n\0"

# displayStr:
#  	movl 4(%esp), %ebx
#  	movl 8(%esp), %ecx
#  	movl $((80*5+0)*2), %edi
#  	movb $0x0c, %ah
# nextChar:
#  	movb (%ebx), %al
#  	movw %ax, %gs:(%edi)
#  	addl $2, %edi
#  	incl %ebx
#  	loopnz nextChar # loopnz decrease ecx by 1
#  	ret

# .p2align 2
# gdt: # 8 bytes for each table entry, at least 1 entry
# 	.word 0,0 # empty entry
# 	.byte 0,0,0,0

# 	# TODO:
# 	# code segment entry
# 	# data segment entry
# 	# graphics segment entry
# 	.word 0xffff,0 # code segment entry
# 	.byte 0,0x9a,0xcf,0

# 	.word 0xffff,0 # data segment entry
# 	.byte 0,0x92,0xcf,0

# 	.word 0xffff,0x8000 # graphics segment entry
# 	.byte 0x0b,0x92,0xcf,0

# 	# # 第一个描述符是NULL
# 	# .word 0,0
# 	# .byte 0,0,0,0

# 	# # TODO：code segment entry
# 	# .word
# 	# .byte 

# 	# # TODO：data segment entry
# 	# .word
# 	# .byte 

# 	# # TODO：graphics segment entry
# 	# .word
# 	# .byte 

# gdtDesc: # 6 bytes in total
# 	.word (gdtDesc - gdt -1) # size of the table, 2 bytes, 65536-1 bytes, 8192 entries
# 	.long gdt # offset, i.e. linear address of the table itself


# TODO: This is lab1.3
# /* Protected Mode Loading Hello World APP */
.code16

.global start
start:
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	# TODO:关闭中断
	cli # clear interuption

	# 启动A20总线
	inb $0x92, %al 
	orb $0x02, %al
	outb %al, $0x92

	# 加载GDTR
	data32 addr32 lgdt gdtDesc # loading gdtr, data32, addr32

	# TODO：设置CR0的PE位（第0位）为1
	movl %cr0, %eax
	orb $0x01, %al
	movl %eax, %cr0 # setting cr0

	# 长跳转切换至保护模式
	data32 ljmp $0x08, $start32 # reload code segment selector and ljmp to start32, data32

.code32
start32:
	movw $0x10, %ax # setting data segment selector
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %ss
	movw $0x18, %ax # setting graphics data segment selector
	movw %ax, %gs
	
	movl $0x8000, %eax # setting esp
	movl %eax, %esp
	jmp bootMain # jump to bootMain in boot.c

.p2align 2
gdt: # 8 bytes for each table entry, at least 1 entry
	# .word 0,0 # empty entry
	# .byte 0,0,0,0

	# .word 0xffff,0 # code segment entry
	# .byte 0,0x9a,0xcf,0

	# .word 0xffff,0 # data segment entry
	# .byte 0,0x92,0xcf,0

	# .word 0xffff,0x8000 # graphics segment entry
	# .byte 0x0b,0x92,0xcf,0

	# .word limit[15:0],base[15:0]
	# .byte base[23:16],(0x90|(type)),(0xc0|(limit[19:16])),base[31:24]

	# 第一个描述符是NULL
	.word 0,0
	.byte 0,0,0,0

	# TODO：code segment entry
	.word 0xffff,0
	.byte 0,0x9a,0xcf,0

	# TODO：data segment entry
	.word 0xffff,0
	.byte 0,0x92,0xcf,0

	# TODO：graphics segment entry
	.word 0xffff,0x8000
	.byte 0x0b,0x92,0xcf,0

gdtDesc: # 6 bytes in total
	.word (gdtDesc - gdt - 1) # size of the table, 2 bytes, 65536-1 bytes, 8192 entries
	.long gdt # offset, i.e. linear address of the table itself
