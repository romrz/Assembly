;;; ;;
;;; This program change the case of one file
;;; and stores the changes in another.
;;; ;;
;;; Execute & Compile
;;; nasm -f elf toggle_case.asm
;;; ld -s -o toggle_case toggle_case.o -m elf_i386
;;; ./toggle_case input_file output_file
;;; ;;

	
BITS 32

%macro exit 0
	mov ebx,0
	mov eax,1
	int 0x80
%endmacro

;; Reads from a file
;; @param 1	File descriptor
;; @param 2	Buffer
;; @param 3	Text length
%macro read 3
	mov edx,%3
	mov ecx,%2
	mov ebx,%1
	mov eax,3
	int 0x80
%endmacro
	
;; Writes to a file
;; @param 1	File descriptor
;; @param 2	Buffer
;; @param 3	Text length
%macro write 3
	mov edx,%3
	mov ecx,%2
	mov ebx,%1
	mov eax,4
	int 0x80
%endmacro

;; Closes a file
;; @param 1	File descriptor
%macro	close_file 1
	mov ebx,%1
	mov eax,6	; sys_close()
	int 0x80	; Kernel call
%endmacro
	
;; Function that opens a file
;; @param ebx	The name file
;; @param edx	1 for create the file if doesn't exist, 0 otherwise
open_file:
	mov ecx,2		; Read and Write mode
	mov eax,5		; sys_open()
	int 0x80		; Interruption 80. kernel call	

	test eax,eax		; Checks for errors
	jns _r_open_file	; If there is no error return

	;; If there's an error try to create the file
	;; only if the user indicates it
	cmp edx,1
	je _create_file

	;; Writes a message and exits the program if there's an error
	_err:
		write 1, open_file_error, len_fne
		exit

	;; Creates the file
	_create_file:
		mov ecx,00700q	; Write, read, and execute Permissions
		mov eax,8	; sys_creat()
		int 0x80	; kernel call
		test eax,eax	; Checks for errors
		js _err		; Show a message if there's an error
	
	_r_open_file:	
	ret

;; Converts charater to upper case
;; @param eax	The character
to_upper_case:
	;; If the character is not a lower case letter return
	cmp eax,97
	jl _return_tuc
	cmp eax,122
	jg _return_tuc

	;; Convert to Upper case
	sub eax,32
	
	_return_tuc:		; Return
	ret

;; Converts charater to lower case
;; @param eax	The character
to_lower_case:
	;; If the character is not an upper case letter return
	cmp eax,65
	jl _return_tlc
	cmp eax,90
	jg _return_tlc

	;; Convert to Upper case
	add eax,32
	
	_return_tlc:		; Return
	ret

;; Toggles the case of the character
;; @param eax	The character
toggle_case:
	;; From uppercase to lowercase
	;; If the character is not an upper case letter check if it's lowercase
	cmp eax,65
	jl _check_lw
	cmp eax,90
	jg _check_lw

	;; Convert to Upper case
	add eax,32
	jmp _return_tc

	;; From lowercase to uppercase
	_check_lw:
	;; If the character is not a lower case letter return
	cmp eax,97
	jl _return_tc
	cmp eax,122
	jg _return_tc

	;; Convert to Upper case
	sub eax,32

	_return_tc:	
	ret

section .data
	open_file_error db "Error: Error opening the file"
	len_fne equ $ - open_file_error

section .bss
	src_file:	resd 1  	; Source file descriptor 
	dest_file:	resd 1   	; Destination file descriptor
	buffer:		resb 1		; Buffer
	
section .text
	global _start
	
_start:
	pop ebx			; argc
	pop ebx			; argv[0] nombre del ejecutable

	;; Open src file
	pop ebx			; Source file name
	mov edx,0		; Don't create the file
	call open_file		; Opens the file
	mov [src_file],eax	; Saves the file descriptor
	
	;; Open dest file
	pop ebx			; dest file name
	mov edx,1		; Create the file if not exists
	call open_file		; Opens the file
	mov [dest_file],eax	; Saves the file descriptor

	;; Converts the src file to upper case char by char and saves it into dest file
	lp:
		;; Reads one character form the source file
		read [src_file], buffer, 1
	
		cmp eax,0		; EOF?
		je _exit		; Exit if eof is reached

		mov eax,[buffer]
		call to_upper_case
		mov [buffer],eax

		;; Writes one character to dest file 
		write [dest_file], buffer, 1
	jmp lp
	
_exit:		
	close_file [src_file]
	close_file [dest_file]
	exit
