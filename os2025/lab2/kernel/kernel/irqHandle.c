#include "x86.h"
#include "device.h"

extern int displayRow;
extern int displayCol;

extern uint32_t keyBuffer[MAX_KEYBUFFER_SIZE];
extern int bufferHead;
extern int bufferTail;
// DO
extern int timeFlag;
// DO OVER

int tail=0;

void GProtectFaultHandle(struct TrapFrame *tf);

//DO
void timerHandler(struct TrapFrame *tf);
// DO OVER
void KeyboardHandle(struct TrapFrame *tf);

void syscallHandle(struct TrapFrame *tf);
void syscallWrite(struct TrapFrame *tf);
void syscallPrint(struct TrapFrame *tf);
void syscallRead(struct TrapFrame *tf);
void syscallGetChar(struct TrapFrame *tf);
void syscallGetStr(struct TrapFrame *tf);
void syscallSetTimeFlag(struct TrapFrame *tf);
void syscallGetTimeFlag(struct TrapFrame *tf);


void irqHandle(struct TrapFrame *tf) { // pointer tf = esp
	/*
	 * 中断处理程序
	 */
	/* Reassign segment register */
	asm volatile("movw %%ax, %%ds"::"a"(KSEL(SEG_KDATA)));

	switch(tf->irq) {
		// TODO: 填好中断处理程序的调用
		case -1:
		case 0x8:
		case 0xa:
		case 0xb:
		case 0xc:
		case 0xe:
		case 0x11:
		case 0x1e:
			break;
		case 0xd:
			GProtectFaultHandle(tf);
			break; 
		case 0x20:
			timerHandler(tf);
			break;
		case 0x21:
			KeyboardHandle(tf);
			break; 
		case 0x80:
			//assert(0);
			syscallHandle(tf);
			break; 
		// OVER TODO
		default:assert(0);
	}
}

void GProtectFaultHandle(struct TrapFrame *tf){
	assert(0);
	return;
}

void KeyboardHandle(struct TrapFrame *tf){
	uint32_t code = getKeyCode();

	if(code == 0xe){ // 退格符
		//要求只能退格用户键盘输入的字符串，且最多退到当行行首
		if(displayCol>0&&displayCol>tail){
			displayCol--;
			uint16_t data = 0 | (0x0c << 8);
			int pos = (80*displayRow+displayCol)*2;
			asm volatile("movw %0, (%1)"::"r"(data),"r"(pos+0xb8000));
		}
	}else if(code == 0x1c){ // 回车符
		//处理回车情况
		keyBuffer[bufferTail++]='\n';
		displayRow++;
		displayCol=0;
		tail=0;
		if(displayRow==25){
			scrollScreen();
			displayRow=24;
			displayCol=0;
		}
	}else if(code < 0x81){ 
		// TODO: 处理正常的字符
		

	}
	updateCursor(displayRow, displayCol);

}

void timerHandler(struct TrapFrame *tf) {
	// TODO
	timeFlag = 1;
	return;
}

void syscallHandle(struct TrapFrame *tf) {
	switch(tf->eax) { // syscall number
		case 0:
			syscallWrite(tf);
			break; // for SYS_WRITE
		case 1:
			syscallRead(tf);
			break; // for SYS_READ
		// DO
		// maybe we can make `syscallHandle` a TODO?
		case 2:
			syscallSetTimeFlag(tf);
			break; // for SYS_SET_FLAG
		case 3:
			syscallGetTimeFlag(tf);
			break; // for SYS_SET_FLAG
		// DO OVER 
		default:break;
	}
}

void syscallWrite(struct TrapFrame *tf) {
	switch(tf->ecx) { // file descriptor
		case 0:
			syscallPrint(tf);
			break; // for STD_OUT
		default:break;
	}
}

void syscallPrint(struct TrapFrame *tf) {
	int sel =  USEL(SEG_UDATA);
	char *str = (char*)tf->edx;
	int size = tf->ebx;
	int i = 0;
	int pos = 0;
	char character = 0;
	uint16_t data = 0;
	asm volatile("movw %0, %%es"::"m"(sel));
	for (i = 0; i < size; i++) {
		asm volatile("movb %%es:(%1), %0":"=r"(character):"r"(str+i));
		// TODO: 完成光标的维护和打印到显存
		if(character == '\n'){
			displayRow++;
			displayCol=0;
			if(displayRow == 25){
				scrollScreen();
				displayRow=24;
				displayCol=0;
			}
		}
		else if(displayCol < 79){
			data = (character & 0xff) | (0x0c << 8);
			pos = (80*displayRow+displayCol)*2;
			asm volatile("movw %0, (%1)"::"r"(data),"r"(pos+0xb8000));
			displayCol++;
		}
		else {
			data = character | (0x0c << 8);
			pos = (80*displayRow+displayCol)*2;
			asm volatile("movw %0, (%1)"::"r"(data),"r"(pos+0xb8000));
			displayRow++;
			displayCol=0;
			if(displayRow == 25){
				scrollScreen();
				displayRow=24;
				displayCol=0;
			}
		}
		// OVER TODO
	}
	tail=displayCol;
	updateCursor(displayRow, displayCol);
}

void syscallRead(struct TrapFrame *tf){
	switch(tf->ecx){ //file descriptor
		case 0:
			syscallGetChar(tf);
			break; // for STD_IN
		case 1:
			syscallGetStr(tf);
			break; // for STD_STR
		default:break;
	}
}

void syscallGetChar(struct TrapFrame *tf){
	// TODO: 自由实现
	tf->eax = keyBuffer[bufferTail-1];
	return;
	// OVER TODO
}

void syscallGetStr(struct TrapFrame *tf){
	// TODO: 自由实现
	// begin : esi = 0
	// waiting : esi = 1
	int sign = 0;
	sign = (int)tf->esi;
	if(sign == 0){
		tf->eax = bufferTail;
		return;
	}
	
	assert(sign == 1);
	// edi = beginTail
	int size = (int)tf->ebx;
	int beginTail = (int)tf->edi;
	if(beginTail == bufferTail){
		//failed == 0
		tf->eax = 0;
	}
	else if(keyBuffer[bufferTail-1] =='\n'){
		//succeed == 1
		tf->eax = 1;

		char* str = (char*)tf->edx;
		int index = 0;
		int limit = 0;
		char character = 0;
		limit = beginTail + size - 1;
		for(index = beginTail;index < limit;index++){
			character = keyBuffer[index];
			if(character == '\n'){
				character = '\0';
				//*(str + (index - beginTail)) = character;
				asm volatile("movb %0, %%es:(%1)"::"r"(character),"r"(str + (index - beginTail)));
				break;
			}
			else{
				//*(str + (index - beginTail)) = character;
				asm volatile("movb %0, %%es:(%1)"::"r"(character),"r"(str + (index - beginTail)));
			}
		}
		character = '\0';
		//*(str + (size - 1)) = character;
		asm volatile("movb %0, %%es:(%1)"::"r"(character),"r"(str + (size - 1)));
	}
	else{
		//failed == 0
		tf->eax = 0;
	}
	return;
	// OVER TODO
}

void syscallGetTimeFlag(struct TrapFrame *tf) {
	// TODO: 自由实现
	tf->eax = timeFlag;
	return;
}

void syscallSetTimeFlag(struct TrapFrame *tf) {
	// TODO: 自由实现
	timeFlag = 0;
	return;
}
