	.text

	.align	16
	.global	reverse32Bit_AVX
	.type	reverse32Bit_AVX, %function
	/*
		void	reverse32Bit_AVX(unsigned int* dest, const unsigned int* src, const unsigned int integerCount)
	*/
reverse32Bit_AVX:
	prefetchnta	(%rsi)
	lea		shuffleIndex(%rip), %r8
	test	%rdx, %rdx
	je,pn	0f

	prefetchnta	64(%rsi)
	vmovdqa		(%r8), %xmm10			/*	xmm10 = {0x06^8, 0x07^8}	*/
	vmovdqa		16(%r8), %xmm11			/*	xmm11 = {0x04^8, 0x05^8}	*/

	/*	3cycle stall	*/
	vpshufd		$0xaa, %xmm11, %xmm14	/*	xmm14 = {0x04^16}	*/
	vmovdqa	32(%r8), %xmm15				/*	xmm15 = {0x0102040810204080^2}	*/
	mov		%rdx, %rcx

	vpsubb		%xmm14, %xmm10, %xmm8	/*	xmm8 = {0x02^8, 0x03^8}	*/
	vpsubb		%xmm14, %xmm11, %xmm9	/*	xmm9 = {0x00^8, 0x01^8}	*/
	shr		$1, %rcx
	je,pn	1f

	vmovq	(%rsi), %xmm12				/*	load 1st pair	*/
	add		$8, %rsi
	/*	3cycle stall	*/
	vpshufb		%xmm8, %xmm12, %xmm0
	vpshufb		%xmm9, %xmm12, %xmm1
	dec		%rcx

	vpshufb		%xmm10, %xmm12, %xmm2
	vpshufb		%xmm11, %xmm12, %xmm3
	vpand		%xmm15, %xmm0, %xmm4

	vpand		%xmm15, %xmm1, %xmm5
	vpand		%xmm15, %xmm2, %xmm6
	je,pn	20f							/*	if only a pair of integers, bypass pair loop	*/

	/*
		xmm8 = {2, 3}, xmm9 = {0, 1}, xmm10 = {6, 7}, xmm11 = {4, 5}
		xmm15 = {0x0102040810204080^2}
	*/
	.align	16
2:
	vmovq		(%rsi), %xmm12
	add		$8, %rsi
	vpcmpeqb	%xmm15, %xmm4, %xmm4
	vpcmpeqb	%xmm15, %xmm5, %xmm5

	vpmovmskb	%xmm4, %r8
	vpcmpeqb	%xmm15, %xmm6, %xmm6
	vpand		%xmm15, %xmm3, %xmm7

	vpmovmskb	%xmm5, %r9
	vpcmpeqb	%xmm15, %xmm7, %xmm7
	add		$8, %rdi

	vpmovmskb	%xmm6, %r10
	mov		%r8w, -8(%rdi)

	vpmovmskb	%xmm7, %r11
	vpshufb		%xmm8, %xmm12, %xmm0
	vpshufb		%xmm9, %xmm12, %xmm1
	mov		%r9w, -6(%rdi)

	vpshufb		%xmm10, %xmm12, %xmm2
	vpshufb		%xmm11, %xmm12, %xmm3
	vpand		%xmm15, %xmm0, %xmm4
	mov		%r10w, -4(%rdi)

	vpand		%xmm15, %xmm1, %xmm5
	vpand		%xmm15, %xmm2, %xmm6
	mov		%r11w, -2(%rdi)
	sub		$1, %rcx
	jne		2b

20:
	vpcmpeqb	%xmm15, %xmm4, %xmm4
	vpcmpeqb	%xmm15, %xmm5, %xmm5
	vpand		%xmm15, %xmm3, %xmm7

	vpmovmskb	%xmm4, %r8
	vpcmpeqb	%xmm15, %xmm6, %xmm6
	vpcmpeqb	%xmm15, %xmm7, %xmm7

	vpmovmskb	%xmm5, %r9

	vpmovmskb	%xmm6, %r10
	prefetchnta	128(%rsi)
	mov		%r8w, (%rdi)

	vpmovmskb	%xmm7, %r11
	mov		%r9w, 2(%rdi)

	mov		%r10w, 4(%rdi)

	mov		%r11w, 6(%rdi)
	add		$8, %rdi

1:
	test	$1, %rdx
	je,pt	0f

	movd	(%rsi), %xmm12
	add		$4, %rsi

	vpshufb	%xmm8, %xmm12, %xmm0
	vpshufb	%xmm9, %xmm12, %xmm1

	vpand	%xmm15, %xmm0, %xmm4
	vpand	%xmm15, %xmm1, %xmm5

	vpcmpeqb	%xmm15, %xmm4, %xmm4
	vpcmpeqb	%xmm15, %xmm5, %xmm5

	vpmovmskb	%xmm4, %r8

	vpmovmskb	%xmm5, %r9

	mov		%r8w, (%rdi)

	mov		%r9w, 2(%rdi)
	add		$4, %rdi

0:
	retq
	.size	reverse32Bit_AVX, .-reverse32Bit_AVX




	.align	16
	.global	reverse32Bit_AVX2
	.type	reverse32Bit_AVX2, %function
	/*
		void	reverse32Bit_AVX2(unsigned int* dest, const unsigned int* src, const unsigned int integerCount)
	*/
reverse32Bit_AVX2:
	prefetchnta	(%rsi)
	lea		shuffleIndex(%rip), %r8
	test	%rdx, %rdx
	je,pn	0f

	prefetchnta	64(%rsi)
	vmovdqa		(%r8), %ymm9			/*	ymm9 = {0x04^8, 0x05^8, 0x06^8, 0x07^8}	*/
	vmovdqa		32(%r8), %ymm15			/*	ymm15 = {0x0102040810204080^2}	*/
	
	vpermq		$0xff, %ymm9, %ymm14	/*	ymm14 = {0x04^16}	*/
	mov		%rdx, %rcx

	vpsubb		%ymm14, %ymm9, %ymm8	/*	ymm8 = {0x00^8, 0x01^8, 0x02^8, 0x03^8}	*/
	vpaddb		%ymm14, %ymm9, %ymm10	/*	ymm10 = {0x08^8, 0x09^8, 0x0a^8, 0x0b^8}	*/

	vpaddb		%ymm14, %ymm10, %ymm11	/*	ymm11 = {0x0c^8, 0x0d^8, 0x0e^8, 0x0f^8}	*/
	shr		$2, %rcx
	je,pn	3f

41:	/*	first 4int	*/
	vlddqu		(%rsi), %xmm12
	add		$16, %rsi

	vinserti128	$1, %xmm12, %ymm12, %ymm13
	sub		$1, %rcx
	je,pn	41f		/*	only first 4int */

42:	/*	second 4int	*/
	vlddqu		(%rsi), %xmm12
	add		$16, %rsi
41:
		vpshufb		%ymm8, %ymm13, %ymm0

		vpshufb		%ymm9, %ymm13, %ymm1
		vpand		%ymm15, %ymm0, %ymm4

		vpshufb		%ymm10, %ymm13, %ymm2
		vpcmpeqb	%ymm15, %ymm4, %ymm4
		vpand		%ymm15, %ymm1, %ymm5

		vpshufb		%ymm11, %ymm13, %ymm3
		vpcmpeqb	%ymm15, %ymm5, %ymm5
		vpand		%ymm15, %ymm2, %ymm6

	vinserti128	$1, %xmm12, %ymm12, %ymm13	/*	useless step when only one 4-int	*/
		vpcmpeqb	%ymm15, %ymm6, %ymm6
		vpand		%ymm15, %ymm3, %ymm7

		vpmovmskb	%ymm4, %r8
		vpcmpeqb	%ymm15, %ymm7, %ymm7

		vpmovmskb	%ymm5, %r9
	je,pn	41f							/* if only 4int, use flag following previous load*/
	sub		$1, %rcx
	je,pn	42f

	/*
		ymm8 = {0, 1, 2, 3}, ymm9 = {4, 5, 6, 7}, ymm10 = {8, 9, a, b}, ymm11 = {c, d, e, f}
		ymm15 = {0x0102040810204080^4}
	*/
	.align	16
4:	/*	3 or more 4int	*/
	vlddqu		(%rsi), %xmm12
	add		$16, %rsi
			vpmovmskb	%ymm6, %r10
		vpshufb		%ymm8, %ymm13, %ymm0
			mov			%r8d, (%rdi)

			vpmovmskb	%ymm7, %r11
		vpshufb		%ymm9, %ymm13, %ymm1
		vpand		%ymm15, %ymm0, %ymm4
			mov			%r9d, 4(%rdi)

		vpshufb		%ymm10, %ymm13, %ymm2
		vpcmpeqb	%ymm15, %ymm4, %ymm4
		vpand		%ymm15, %ymm1, %ymm5
			mov			%r10d, 8(%rdi)

		vpshufb		%ymm11, %ymm13, %ymm3
		vpcmpeqb	%ymm15, %ymm5, %ymm5
		vpand		%ymm15, %ymm2, %ymm6
			mov			%r11d, 12(%rdi)

	vinserti128	$1, %xmm12, %ymm12, %ymm13
		vpcmpeqb	%ymm15, %ymm6, %ymm6
		vpand		%ymm15, %ymm3, %ymm7

		vpmovmskb	%ymm4, %r8
		vpcmpeqb	%ymm15, %ymm7, %ymm7
			add		$16, %rdi

		vpmovmskb	%ymm5, %r9
	sub		$1, %rcx
	jne		4b

42:	/*	last two 4int under processing	*/
			vpmovmskb	%ymm6, %r10
		vpshufb		%ymm8, %ymm13, %ymm0
			mov			%r8d, (%rdi)

			vpmovmskb	%ymm7, %r11
		vpshufb		%ymm9, %ymm13, %ymm1
		vpand		%ymm15, %ymm0, %ymm4
			mov			%r9d, 4(%rdi)

		vpshufb		%ymm10, %ymm13, %ymm2
		vpcmpeqb	%ymm15, %ymm4, %ymm4
		vpand		%ymm15, %ymm1, %ymm5
			mov			%r10d, 8(%rdi)

		vpshufb		%ymm11, %ymm13, %ymm3
		vpcmpeqb	%ymm15, %ymm5, %ymm5
		vpand		%ymm15, %ymm2, %ymm6
			mov			%r11d, 12(%rdi)

		vpcmpeqb	%ymm15, %ymm6, %ymm6
		vpand		%ymm15, %ymm3, %ymm7
			add		$16, %rdi

		vpmovmskb	%ymm4, %r8
		vpcmpeqb	%ymm15, %ymm7, %ymm7

		vpmovmskb	%ymm5, %r9

41:	/*	last 4int to save	*/
			vpmovmskb	%ymm6, %r10
			mov			%r8d, (%rdi)

			vpmovmskb	%ymm7, %r11
			mov			%r9d, 4(%rdi)

			mov			%r10d, 8(%rdi)

			mov			%r11d, 12(%rdi)
			add		$16, %rdi

3:
	and		$3, %rdx
	je,pn	0f

1:
	vpbroadcastd	(%rsi), %ymm12
	add		$4, %rsi

	vpshufb		%ymm8, %ymm12, %ymm0
	vpand		%ymm15, %ymm0, %ymm4
	vpcmpeqb	%ymm15, %ymm4, %ymm4
	vpmovmskb	%ymm4, %r8
	mov			%r8d, (%rdi)
	add		$4, %rdi
	sub		$1, %rdx
	jne,pt	1b

0:
	retq
	.size	reverse32Bit_AVX2, .-reverse32Bit_AVX2

	.align	64
shuffleIndex:
	.fill	8, 1, 0x7
	.fill	8, 1, 0x6
	.fill	8, 1, 0x5
	.fill	8, 1, 0x4
reverseMask:
	.rep	4
	.quad	0x0102040810204080
	.endr
