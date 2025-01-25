/* Real Mode Hello World with clock func*/
 .code16

 .global start
start:
 	movw %cs, %ax
 	movw %ax, %ds
 	movw %ax, %es
 	movw %ax, %ss
	movw $0x7d00, %ax
	movw %ax, %sp # setting stack pointer to 0x7d00
	
    # DO: for clock
	# 设置定时器0 （8253/8254） 以产生时钟中断
	movw $clock_handler, 0x70    
	movw $0, 0x72 
    # 发送命令字节到控制寄存器端口0x43
    movw $0x36, %ax         #方式3 ， 用于定时产生中断00110110b
    movw $0x43, %dx
    out %al, %dx 
            # 计算计数值， 产生20 毫秒的时钟中断， 时钟频率为1193180 赫兹
            # 计数值 = ( 时钟频率/ 每秒中断次数) − 1
            #       = (1193180 / (1 / 0 . 0 2 ) ) − 1= 23863
    movw $23863, %ax
            # 将计数值分为低字节和高字节， 发送到计数器0的数据端口（ 端口0x40 ）
    movw $0x40, %dx
    out %al, %dx 
    mov %ah, %al
    out %al, %dx

	callw loop

loop:
	jmp loop

message_a:
	.string "0 <= counter < 100\n\0"

message_b:
	.string "100 <= counter < 200\n\0"

message_c:
	.string "counter == 200\n\0"

counter:
	.word 0

print_line:
	.word 0

displayStr:
 	pushw %bp
 	movw 4(%esp), %ax
	movw %ax, %bp

 	movw 6(%esp), %cx	# 打印的字符串长度
	movw $0x1301, %ax	# AH=0x13 打印字符串
 	movw $0x000c, %bx	# BH=0x00 黑底 BL=0x0c 红字
	movw print_line, %dx	# 在第0行0列开始打印
 	int $0x10			# 陷入0x10号中断

	movw print_line, %ax
	incw %ax
	movw %ax, print_line

  	popw %bp
	ret
        
clock_handler:  
	pushw %bp
	pushw %ax
	pushw %bx

	# INCREASE counter
	movw counter, %ax
	incw %ax
	movw %ax, counter

	movw counter, %ax
	cmpw $200, %ax
	jb end_handler

	pushw $15
	pushw $message_c
	callw displayStr     

	# RESET counter		
	movw $0, %ax
	movw %ax, counter
	jmp end_handler

end_handler:
	popw %bx
	popw %ax
	popw %bp
	iret
	