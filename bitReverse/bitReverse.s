	.text

	.align	16
	.global	reverse32Bit_AVX
	.type	reverse32Bit_AVX, %function
	/*
		void	reverse32Bit_AVX(unsigned int* dest, const unsigned int* src, const unsigned int integerCount)

		8int/5cycle sustained without actual memory performance issue
		on i7-4930K@3.9GHz, 4e8 integers takes 0.20sec, ~=16GB/s
	*/
reverse32Bit_AVX:
	prefetchnta	(%rsi)
	lea		lowNibbleShuffle(%rip), %r8
	test	%rdx, %rdx
	je,pn	0f

	prefetchnta	64(%rsi)
	vmovdqa		(%r8), %xmm12			/*	xmm12 = low nibble shuffle	*/
	vmovdqa		16(%r8), %xmm13			/*	xmm13 = high nibble shuffle	*/
	mov		%rdx, %rcx

	vmovdqa		32(%r8), %xmm14			/*	xmm14 = low nibble mask	*/
	vmovdqa		48(%r8), %xmm15			/*	xmm15 = byte swap shuffle	*/
	and		$7, %rdx

	vpmovzxbd	64(%r8), %xmm6
	vpmovzxbd	68(%r8), %xmm7
	vmovq	%rdx, %xmm4
	shr		$3, %rcx
	je,pn	7f

	vlddqu		(%rsi), %xmm8
	vlddqu		16(%rsi), %xmm9
	add		$32, %rsi
	/*	4cycle stall	*/
	vpshufb		%xmm15, %xmm8, %xmm10	/*	swap 1st 4int byte order	*/
	vpshufb		%xmm15, %xmm9, %xmm11	/*	swap 2nd 4int byte order	*/

	dec		%rcx
	je,pn	80f

	/*
		xmm12 = low nibble shuffle, xmm13 = high nibble shuffle, xmm14 = low nibble mask
		xmm15 = byte swap shuffle
	*/
	.align	16
8:
	vlddqu		(%rsi), %xmm8
	vlddqu		16(%rsi), %xmm9
		vpandn		%xmm10, %xmm14, %xmm0	/*	1st 4int high nibble	*/
		vpand		%xmm10, %xmm14, %xmm2	/*	1st 4int low nibble	*/
	add		$32, %rsi

		vpsrld		$4, %xmm0, %xmm0		/*	1st 4int high nibble shift to low	*/
		vpandn		%xmm11, %xmm14, %xmm1	/*	2nd 4int high nibble	*/
		vpand		%xmm11, %xmm14, %xmm3	/*	2nd 4int low nibble	*/

		vpsrld		$4, %xmm1, %xmm1		/*	2nd 4int high nibble shift to low	*/
		vpshufb		%xmm0, %xmm13, %xmm0	/*	1st 4int high nibble reverse	*/
		vpshufb		%xmm2, %xmm12, %xmm2	/*	1st 4int low nibble reverse	*/

		vpshufb		%xmm1, %xmm13, %xmm1	/*	2nd 4int high nibble reverse	*/
		vpshufb		%xmm3, %xmm12, %xmm3	/*	2nd 4int low nibble reverse	*/
		vpor		%xmm0, %xmm2, %xmm0		/*	1st bit reverse	*/		

		vmovdqu		%xmm0, (%rdi)
		vpor		%xmm1, %xmm3, %xmm1		/*	2nd bit reverse	*/
		add		$32, %rdi

	vpshufb		%xmm15, %xmm8, %xmm10		/*	swap 1st 4int byte order	*/
	vpshufb		%xmm15, %xmm9, %xmm11		/*	swap 2nd 4int byte order	*/
		vmovdqu		%xmm1, -16(%rdi)
	dec		%rcx
	jne,pt	8b

80:
		vpandn		%xmm10, %xmm14, %xmm0	/*	1st 4int high nibble	*/
		vpand		%xmm10, %xmm14, %xmm2	/*	1st 4int low nibble	*/

		vpsrld		$4, %xmm0, %xmm0		/*	1st 4int high nibble shift to low	*/
		vpandn		%xmm11, %xmm14, %xmm1	/*	2nd 4int high nibble	*/
		vpand		%xmm11, %xmm14, %xmm3	/*	2nd 4int low nibble	*/

		vpsrld		$4, %xmm1, %xmm1		/*	2nd 4int high nibble shift to low	*/
		vpshufb		%xmm0, %xmm13, %xmm0	/*	1st 4int high nibble reverse	*/
		vpshufb		%xmm2, %xmm12, %xmm2	/*	1st 4int low nibble reverse	*/

		vpshufb		%xmm1, %xmm13, %xmm1	/*	2nd 4int high nibble reverse	*/
		vpshufb		%xmm3, %xmm12, %xmm3	/*	2nd 4int low nibble reverse	*/
		vpor		%xmm0, %xmm2, %xmm0		/*	1st bit reverse	*/		

		vmovdqu		%xmm0, (%rdi)
		vpor		%xmm1, %xmm3, %xmm1		/*	2nd bit reverse	*/

		vmovdqu		%xmm1, 16(%rdi)
		add		$32, %rdi
7:
	vpshufd		$0, %xmm4, %xmm4

	vpcmpgtd	%xmm6, %xmm4, %xmm6
	vpcmpgtd	%xmm7, %xmm4, %xmm7

	vmaskmovps	(%rsi), %xmm6, %xmm8
	vmaskmovps	16(%rsi), %xmm7, %xmm9

	vpshufb		%xmm15, %xmm8, %xmm10		/*	swap 1st 4int byte order	*/
	vpshufb		%xmm15, %xmm9, %xmm11		/*	swap 2nd 4int byte order	*/

		vpandn		%xmm10, %xmm14, %xmm0	/*	1st 4int high nibble	*/
		vpand		%xmm10, %xmm14, %xmm2	/*	1st 4int low nibble	*/

		vpsrld		$4, %xmm0, %xmm0		/*	1st 4int high nibble shift to low	*/
		vpandn		%xmm11, %xmm14, %xmm1	/*	2nd 4int high nibble	*/
		vpand		%xmm11, %xmm14, %xmm3	/*	2nd 4int low nibble	*/

		vpsrld		$4, %xmm1, %xmm1		/*	2nd 4int high nibble shift to low	*/
		vpshufb		%xmm0, %xmm13, %xmm0	/*	1st 4int high nibble reverse	*/
		vpshufb		%xmm2, %xmm12, %xmm2	/*	1st 4int low nibble reverse	*/

		vpshufb		%xmm1, %xmm13, %xmm1	/*	2nd 4int high nibble reverse	*/
		vpshufb		%xmm3, %xmm12, %xmm3	/*	2nd 4int low nibble reverse	*/
		vpor		%xmm0, %xmm2, %xmm0		/*	1st bit reverse	*/		

		vmaskmovps		%xmm0, %xmm6, (%rdi)
		vpor		%xmm1, %xmm3, %xmm1		/*	2nd bit reverse	*/

		vmaskmovps		%xmm1, %xmm7, 16(%rdi)

0:
	retq
	.size	reverse32Bit_AVX, .-reverse32Bit_AVX

	.align	16
lowNibbleShuffle:
	.byte	0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0, 0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0
highNibbleShuffle:
	.byte	0x00, 0x08, 0x04, 0x0c, 0x02, 0x0a, 0x06, 0x0e, 0x01, 0x09, 0x05, 0x0d, 0x03, 0x0b, 0x07, 0x0f
lowNibbleMask:
	.fill	16, 1, 0x0f
swapShuffle:
	.byte	0x03, 0x02, 0x01, 0x00, 0x07, 0x06, 0x05, 0x04, 0x0b, 0x0a, 0x09, 0x08, 0x0f, 0x0e, 0x0d, 0x0c
maskToCount:
	.byte	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

	.align	16
	.global	reverse32Bit_AVX2
	.type	reverse32Bit_AVX2, %function
	/*
		void	reverse32Bit_AVX2(unsigned int* dest, const unsigned int* src, const unsigned int integerCount)

		16int/6cycle sustained without actual memory performance issue
		on i7-4650U@3.3GHz, 1e8 integers takes 0.0687sec, ~=11.65GB/s
	*/
reverse32Bit_AVX2:
	prefetchnta	(%rsi)
	lea		lowNibbleShuffle(%rip), %r8
	test	%rdx, %rdx
	je,pn	0f

	prefetchnta	64(%rsi)
	vbroadcasti128	(%r8), %ymm12		/*	ymm12 = low nibble shuffle	*/
	vbroadcasti128	16(%r8), %ymm13		/*	ymm13 = high nibble shuffle	*/
	mov		%rdx, %rcx

	vbroadcasti128	32(%r8), %ymm14		/*	ymm14 = low nibble mask	*/
	vbroadcasti128	48(%r8), %ymm15		/*	ymm15 = byte swap shuffle	*/
	and		$15, %rdx

	vpmovzxbd	64(%r8), %ymm6
	vpmovzxbd	72(%r8), %ymm7
	vmovq	%rdx, %xmm4
	shr		$4, %rcx
	je,pn	15f

	vlddqu		(%rsi), %ymm8
	vlddqu		32(%rsi), %ymm9
	add		$64, %rsi
	/*	4cycle stall	*/
	vpshufb		%ymm15, %ymm8, %ymm10	/*	swap 1st 8int byte order	*/

	vpshufb		%ymm15, %ymm9, %ymm11	/*	swap 2nd 8int byte order	*/

	dec		%rcx
	je,pn	160f

	/*
		xmm12 = low nibble shuffle, xmm13 = high nibble shuffle, xmm14 = low nibble mask
		xmm15 = byte swap shuffle
	*/
	.align	16
16:
	vlddqu		(%rsi), %ymm8
	vlddqu		32(%rsi), %ymm9
	add		$64, %rsi
		vpandn		%ymm10, %ymm14, %ymm0	/*	1st 8int high nibble	*/
		vpandn		%ymm11, %ymm14, %ymm1	/*	2nd 8int high nibble	*/

		vpsrld		$4, %ymm0, %ymm0		/*	1st 8int high nibble shift to low	*/
		vpand		%ymm10, %ymm14, %ymm2	/*	1st 8int low nibble	*/
		vpand		%ymm11, %ymm14, %ymm3	/*	2nd 8int low nibble	*/

		vpsrld		$4, %ymm1, %ymm1		/*	2nd 8int high nibble shift to low	*/
		vpshufb		%ymm0, %ymm13, %ymm0	/*	1st 8int high nibble reverse	*/

		vpshufb		%ymm2, %ymm12, %ymm2	/*	1st 8int low nibble reverse	*/

		vpshufb		%ymm1, %ymm13, %ymm1	/*	2nd 8int high nibble reverse	*/
		vpor		%ymm0, %ymm2, %ymm0		/*	1st bit reverse	*/		

		vpshufb		%ymm3, %ymm12, %ymm3	/*	2nd 8int low nibble reverse	*/
		vmovdqu		%ymm0, (%rdi)

	vpshufb		%ymm15, %ymm8, %ymm10		/*	swap 1st 8int byte order	*/
		vpor		%ymm1, %ymm3, %ymm1		/*	2nd bit reverse	*/

	vpshufb		%ymm15, %ymm9, %ymm11		/*	swap 2nd 8int byte order	*/
		vmovdqu		%ymm1, 32(%rdi)
		add		$64, %rdi
	dec		%rcx
	jne,pt	16b

160:
		vpandn		%ymm10, %ymm14, %ymm0	/*	1st 8int high nibble	*/
		vpandn		%ymm11, %ymm14, %ymm1	/*	2nd 8int high nibble	*/

		vpsrld		$4, %ymm0, %ymm0		/*	1st 8int high nibble shift to low	*/
		vpand		%ymm10, %ymm14, %ymm2	/*	1st 8int low nibble	*/
		vpand		%ymm11, %ymm14, %ymm3	/*	2nd 8int low nibble	*/

		vpsrld		$4, %ymm1, %ymm1		/*	2nd 8int high nibble shift to low	*/
		vpshufb		%ymm0, %ymm13, %ymm0	/*	1st 8int high nibble reverse	*/

		vpshufb		%ymm2, %ymm12, %ymm2	/*	1st 8int low nibble reverse	*/

		vpshufb		%ymm1, %ymm13, %ymm1	/*	2nd 8int high nibble reverse	*/
		vpor		%ymm0, %ymm2, %ymm0		/*	1st bit reverse	*/		

		vpshufb		%ymm3, %ymm12, %ymm3	/*	2nd 8int low nibble reverse	*/
		vmovdqu		%ymm0, (%rdi)

		vpor		%ymm1, %ymm3, %ymm1		/*	2nd bit reverse	*/

		vmovdqu		%ymm1, 32(%rdi)
		add		$64, %rdi

15:
	vinserti128	$1, %xmm4, %ymm4, %ymm4

	vpshufd		$0, %ymm4, %ymm4

	vpcmpgtd	%ymm6, %ymm4, %ymm6
	vpcmpgtd	%ymm7, %ymm4, %ymm7

	vpmaskmovd	(%rsi), %ymm6, %ymm8
	vpmaskmovd	32(%rsi), %ymm7, %ymm9

	vpshufb		%ymm15, %ymm8, %ymm10		/*	swap 1st 8int byte order	*/
	vpshufb		%ymm15, %ymm9, %ymm11		/*	swap 2nd 8int byte order	*/

		vpandn		%ymm10, %ymm14, %ymm0	/*	1st 8int high nibble	*/
		vpandn		%ymm11, %ymm14, %ymm1	/*	2nd 8int high nibble	*/

		vpsrld		$4, %ymm0, %ymm0		/*	1st 8int high nibble shift to low	*/
		vpand		%ymm10, %ymm14, %ymm2	/*	1st 8int low nibble	*/
		vpand		%ymm11, %ymm14, %ymm3	/*	2nd 8int low nibble	*/

		vpsrld		$4, %ymm1, %ymm1		/*	2nd 8int high nibble shift to low	*/
		vpshufb		%ymm0, %ymm13, %ymm0	/*	1st 8int high nibble reverse	*/

		vpshufb		%ymm2, %ymm12, %ymm2	/*	1st 8int low nibble reverse	*/

		vpshufb		%ymm1, %ymm13, %ymm1	/*	2nd 8int high nibble reverse	*/
		vpor		%ymm0, %ymm2, %ymm0		/*	1st bit reverse	*/		

		vpshufb		%ymm3, %ymm12, %ymm3	/*	2nd 8int low nibble reverse	*/
		vpmaskmovd	%ymm0, %ymm6, (%rdi)

		vpor		%ymm1, %ymm3, %ymm1		/*	2nd bit reverse	*/

		vpmaskmovd	%ymm1, %ymm7, 32(%rdi)

0:
	retq
	.size	reverse32Bit_AVX2, .-reverse32Bit_AVX2
