.PHONY: all inverse_permutation clean

all:

inverse_permutation:
	gcc -c -Wall -Wextra -std=c17 -O2 $@.c -o $@.o
	objdump -d -M intel-mnemonic $@.o

src:
	gcc -c -Wall -Wextra -std=c17 -O2 $@.c -o $@.o -g
	objdump -d -M intel-mnemonic $@.o

asm:
	nasm -f elf64 -w+all -w+error -F dwarf -g -o inverse_permutation.o inverse_permutation.asm
	gcc -g -c -Wall -Wextra -std=c17 -O2 -o inverse_permutation_example.o inverse_permutation_example.c
	gcc -g -z noexecstack -o inverse_permutation_example.out inverse_permutation_example.o inverse_permutation.o
	size inverse_permutation.o

asm_prod:
	nasm -f elf64 -w+all -w+error -o inverse_permutation.o inverse_permutation.asm
	gcc -c -Wall -Wextra -std=c17 -O2 -o inverse_permutation_example.o inverse_permutation_example.c
	gcc -z noexecstack -o inverse_permutation_example.out inverse_permutation_example.o inverse_permutation.o

clean:
	rm -rf *.o
