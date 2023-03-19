gcc -c -Wall -Wextra -std=c17 -O2 src.c -o src.o
objdump -d -M intel-mnemonic src.o

src.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <inverse_permutation>:
   0:	48 8d 57 ff          	lea    rdx,[rdi-0x1]
   4:	48 81 fa ff ff ff 7f 	cmp    rdx,0x7fffffff
   b:	77 50                	ja     5d <inverse_permutation+0x5d>
   d:	48 89 f0             	mov    rax,rsi
  10:	48 89 f9             	mov    rcx,rdi
  13:	31 f6                	xor    esi,esi
  15:	eb 20                	jmp    37 <inverse_permutation+0x37>
  17:	66 0f 1f 84 00 00 00 	nop    WORD PTR [rax+rax*1+0x0]
  1e:	00 00 
  20:	48 63 fa             	movsxd rdi,edx
  23:	48 39 cf             	cmp    rdi,rcx
  26:	73 16                	jae    3e <inverse_permutation+0x3e>
  28:	83 c2 01             	add    edx,0x1
  2b:	89 14 b0             	mov    DWORD PTR [rax+rsi*4],edx
  2e:	48 83 c6 01          	add    rsi,0x1
  32:	48 39 ce             	cmp    rsi,rcx
  35:	74 29                	je     60 <inverse_permutation+0x60>
  37:	8b 14 b0             	mov    edx,DWORD PTR [rax+rsi*4]
  3a:	85 d2                	test   edx,edx
  3c:	79 e2                	jns    20 <inverse_permutation+0x20>
  3e:	8d 56 ff             	lea    edx,[rsi-0x1]
  41:	85 f6                	test   esi,esi
  43:	74 18                	je     5d <inverse_permutation+0x5d>
  45:	48 63 d2             	movsxd rdx,edx
  48:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
  4f:	00 
  50:	83 2c 90 01          	sub    DWORD PTR [rax+rdx*4],0x1
  54:	48 83 ea 01          	sub    rdx,0x1
  58:	83 fa ff             	cmp    edx,0xffffffff
  5b:	75 f3                	jne    50 <inverse_permutation+0x50>
  5d:	31 c0                	xor    eax,eax
  5f:	c3                   	ret
  60:	53                   	push   rbx
  61:	49 89 c1             	mov    r9,rax
  64:	4c 8d 14 88          	lea    r10,[rax+rcx*4]
  68:	ba 01 00 00 00       	mov    edx,0x1
  6d:	41 bb 01 00 00 00    	mov    r11d,0x1
  73:	8d 72 ff             	lea    esi,[rdx-0x1]
  76:	48 89 c7             	mov    rdi,rax
  79:	eb 24                	jmp    9f <inverse_permutation+0x9f>
  7b:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
  80:	4c 8d 44 90 fc       	lea    r8,[rax+rdx*4-0x4]
  85:	41 8b 10             	mov    edx,DWORD PTR [r8]
  88:	89 d3                	mov    ebx,edx
  8a:	0f af de             	imul   ebx,esi
  8d:	85 db                	test   ebx,ebx
  8f:	78 1f                	js     b0 <inverse_permutation+0xb0>
  91:	f7 da                	neg    edx
  93:	48 83 c7 04          	add    rdi,0x4
  97:	41 89 10             	mov    DWORD PTR [r8],edx
  9a:	4c 39 d7             	cmp    rdi,r10
  9d:	74 1d                	je     bc <inverse_permutation+0xbc>
  9f:	48 63 17             	movsxd rdx,DWORD PTR [rdi]
  a2:	85 d2                	test   edx,edx
  a4:	7f da                	jg     80 <inverse_permutation+0x80>
  a6:	74 08                	je     b0 <inverse_permutation+0xb0>
  a8:	f7 da                	neg    edx
  aa:	48 63 d2             	movsxd rdx,edx
  ad:	eb d1                	jmp    80 <inverse_permutation+0x80>
  af:	90                   	nop
  b0:	48 83 c7 04          	add    rdi,0x4
  b4:	45 31 db             	xor    r11d,r11d
  b7:	4c 39 d7             	cmp    rdi,r10
  ba:	75 e3                	jne    9f <inverse_permutation+0x9f>
  bc:	31 d2                	xor    edx,edx
  be:	83 fe ff             	cmp    esi,0xffffffff
  c1:	75 b0                	jne    73 <inverse_permutation+0x73>
  c3:	45 84 db             	test   r11b,r11b
  c6:	74 40                	je     108 <inverse_permutation+0x108>
  c8:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
  cf:	00 
  d0:	4c 63 c1             	movsxd r8,ecx
  d3:	4a 8d 7c 80 fc       	lea    rdi,[rax+r8*4-0x4]
  d8:	8b 17                	mov    edx,DWORD PTR [rdi]
  da:	85 d2                	test   edx,edx
  dc:	7e 7a                	jle    158 <inverse_permutation+0x158>
  de:	66 90                	xchg   ax,ax
  e0:	48 63 fa             	movsxd rdi,edx
  e3:	42 89 74 80 fc       	mov    DWORD PTR [rax+r8*4-0x4],esi
  e8:	41 89 d0             	mov    r8d,edx
  eb:	89 ce                	mov    esi,ecx
  ed:	48 8d 7c b8 fc       	lea    rdi,[rax+rdi*4-0x4]
  f2:	f7 de                	neg    esi
  f4:	8b 17                	mov    edx,DWORD PTR [rdi]
  f6:	85 d2                	test   edx,edx
  f8:	78 2e                	js     128 <inverse_permutation+0x128>
  fa:	44 89 c1             	mov    ecx,r8d
  fd:	74 21                	je     120 <inverse_permutation+0x120>
  ff:	4d 63 c0             	movsxd r8,r8d
 102:	eb dc                	jmp    e0 <inverse_permutation+0xe0>
 104:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
 108:	41 83 29 01          	sub    DWORD PTR [r9],0x1
 10c:	49 83 c1 04          	add    r9,0x4
 110:	4d 39 d1             	cmp    r9,r10
 113:	75 f3                	jne    108 <inverse_permutation+0x108>
 115:	45 31 db             	xor    r11d,r11d
 118:	44 89 d8             	mov    eax,r11d
 11b:	5b                   	pop    rbx
 11c:	c3                   	ret
 11d:	0f 1f 00             	nop    DWORD PTR [rax]
 120:	31 c9                	xor    ecx,ecx
 122:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
 128:	89 0f                	mov    DWORD PTR [rdi],ecx
 12a:	44 89 c1             	mov    ecx,r8d
 12d:	83 e9 01             	sub    ecx,0x1
 130:	75 9e                	jne    d0 <inverse_permutation+0xd0>
 132:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
 138:	41 83 29 01          	sub    DWORD PTR [r9],0x1
 13c:	49 83 c1 04          	add    r9,0x4
 140:	4d 39 ca             	cmp    r10,r9
 143:	74 d3                	je     118 <inverse_permutation+0x118>
 145:	41 83 29 01          	sub    DWORD PTR [r9],0x1
 149:	49 83 c1 04          	add    r9,0x4
 14d:	4d 39 ca             	cmp    r10,r9
 150:	75 e6                	jne    138 <inverse_permutation+0x138>
 152:	eb c4                	jmp    118 <inverse_permutation+0x118>
 154:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
 158:	41 89 c8             	mov    r8d,ecx
 15b:	89 d1                	mov    ecx,edx
 15d:	f7 d9                	neg    ecx
 15f:	89 0f                	mov    DWORD PTR [rdi],ecx
 161:	44 89 c1             	mov    ecx,r8d
 164:	83 e9 01             	sub    ecx,0x1
 167:	0f 85 63 ff ff ff    	jne    d0 <inverse_permutation+0xd0>
 16d:	eb c9                	jmp    138 <inverse_permutation+0x138>
