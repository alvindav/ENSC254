#include <stdint.h>
#include <stdio.h>

extern void asm_main();
extern void toTera(char a);

int main()
{

	asm_main();

    return 0;
}

int16_t div(int16_t x, int16_t y){
	return x/y;
}

int16_t mul(int16_t x, int16_t y){
	return x*y;
}

int16_t mod(int16_t x, int16_t y){
	return x%y;
}

void PRINT_NUM(int16_t x){
	char buffer[128];
	sprintf(buffer, "%i", x);
	int i = 0;
	while(1){
		if(buffer[i] == '\0')
			break;

		toTera(buffer[i]);
		i++;
	}
}
