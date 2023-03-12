Pliki asemblerowe kompiluje się poleceniem:
```
nasm -f elf64 -w+all -w+error -o macX.o macX.asm
```
Dostarczone w plikach `macX_test.c` programy testujące w języku C kompilują się
i całość konsoliduje się poleceniami:
```
gcc -c -Wall -Wextra -std=c17 -O2 -o macX_test.o macX_test.c
gcc -z noexecstack -o macX_test macX.o macX_test.o
```
