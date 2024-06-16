; imports the c runtime printf function
; used to display information to the user
extern printf
; imports the c runtime scanf function
; used to get input from the user
extern scanf

; defines the data section of the PE file
section .data
	; various printable strings
	; the string the user will see during the program loop
	Notify: db "Please enter a question: ", 0x0
	; used to clear the input buffer
	ClearInput: db "%c", 0x0
	; uses for string input
	InputString: db "%[^", 0xA, "]s", 0x0
	; displays a formatted question and answer to the user
	FormatString: db "%s = %i", 0xA, 0x0
	; various operators
	; used to differentiate between operators
	Addition: db " + ", 0x0
	Subtract: db " - ", 0x0
	Multiply: db " * ", 0x0
	Divide: db " / ", 0x0

; defines the text section of the PE file
section .text
	
	; finds an occurance of a string within a string and returns the index
	; source - the source string to find the index
	; target - the target string to find within the source string
	; int __stdcall _string_find(const char* source, const char* target)
	_string_find:
		; sets the source string index
		xor rax, rax
	_string_find_reset_target_index:
		; sets the target string index to zero
		xor r10, r10
		; iterates through the characters in the source string
	_string_find_cmp_loop:
		; preserves the source index by adding the target index and saving in r11
		lea r11, [rax+r10]
		; gets the character at the source string index
		mov r8b, byte [rcx+r11]
		; gets the character at the target string index
		mov r9b, byte [rdx+r10]
		; compares the target character to a null byte (the end of an ansi string)
		cmp r9b, 0x0
		; ends the function if a null byte in found
		je _string_find_success
		; compares the source character to a null byte (the end of an ansi string)
		cmp r8b, 0x0
		; ends the function if a null byte in found
		je _string_find_fail
		; increments the target string index
		inc r10
		; compares both characters
		cmp r8b, r9b
		; jumps to the top of the loop if the characters are equal
		je _string_find_cmp_loop
		; increments the source string index
		inc rax
		; unconditionally jumps to the target index reset label
		jmp _string_find_reset_target_index
	_string_find_fail:
		; sets the return value to -1
		mov rax, -1
	_string_find_success:
		; returns the index to the caller
		ret
	
	; returns the length of the given string
	; string - the string to find the length of
	; int __stdcall _string_length(const char* string)
	_string_length:
		; saves rdi
		push rdi
		; saves the original pointer
		lea rdx, [rcx]
		; loads the string pointer into rdi, this will be iterated by repne scasb
		lea rdi, [rcx]
		; allows the instruction to loop forever
		mov rcx, 0xFFFFFFFFFFFFFFFF
		; set the target byte as the null byte
		xor al, al
		; increments the string pointer until a null byte is found
		repne scasb
		; decrements the resulting pointer since scab will still increment it even after it finds the null byte
		dec rdi
		; calculates the string length by subtracting the new pointer from the old pointer
		sub rdi, rdx
		; returns the string length
		mov rax, rdi
		; restores rdi
		pop rdi
		; returns to the caller
		ret
	
	; splits a string by the given string
	; source - the source string to split
	; target - the string to split the source by
	; firsthalf - a pointer to a buffer that will recieve the first half of the split string
	; secondhalf - a pointer to a buffer that will recieve the second half of the split string
	; void __stdcall _string_split(const char* source, const char* target, const char* firsthalf, const char* secondhalf)
	_string_split:
		; saves rdi
		push rdi
		; saves rsi
		push rsi
		; creates some stack space
		sub rsp, 0x28
		; saves the first argument to the stack
		mov qword [rsp], rcx
		; saves the second argument to the stack
		mov qword [rsp+8], rdx
		; saves the third argument to the stack
		mov qword [rsp+0x10], r8
		; saves the fourth argument to the stack
		mov qword [rsp+0x18], r9
		; attempts to find the second string within the first string
		call _string_find
		; checks if it was found
		cmp rax, -1
		; function failed
		je _string_split_return
		; saves the result on the stack
		mov qword [rsp+0x20], rax
		; adds the target string as an argument
		mov rcx, qword [rsp+8]
		; gets the length of the target string
		call _string_length
		; sets the source string address
		mov rsi, qword [rsp]
		; sets the destination address to the first buffer
		mov rdi, qword [rsp+0x10]
		; sets counter to the index of the target string
		mov rcx, qword [rsp+0x20]
		; copies the string to the target buffer
		rep movsb
		; adds the null byte
		mov byte [rdi], 0
		; increments the source string address by the target length
		add rsi, rax
		; adds the target string as an argument
		mov rcx, rsi
		; gets the length of the second half of the source string
		call _string_length
		; sets the counter to the length of the second string
		mov rcx, rax
		; sets the destination address to the second buffer
		mov rdi, qword [rsp+0x18]
		; copies the string to the target buffer
		rep movsb
		; adds the null byte
		mov byte [rdi], 0
	_string_split_return:
		; restores the stack
		add rsp, 0x28
		; restores rsi
		pop rsi
		; restores rdi
		pop rdi
		; returns
		ret
	
	; converts a string to an int
	; string - the string to convert to an int
	; int __stdcall _string_to_int(const char* string)
	_string_to_int:
		; preserves the rdi register
		push rdi
		; saves the argument
		lea rdi, [rcx]
		; gets the length of the string
		call _string_length
		; stores the string index
		mov r8, rax
		; stores the result
		xor r10, r10
		; gets the first character from the string
		mov r9b, [rdi]
		; compares it to the minus ascii code
		cmp r9b, 0x2D
		; if it's equal then jump
		je _string_to_int_negative
		; stores the positive power
		mov r11, 1
		; jumps over the negative power
		jmp _string_to_int_convert_loop
	_string_to_int_negative:
		; decrements the string length
		dec r8
		; increments the string pointer in order to avoid the minus character
		inc rdi
		; stores the negative power
		mov r11, -1
	_string_to_int_convert_loop:
		; decrements the index
		dec r8
		; compares the index to zero
		cmp r8, 0
		; if the index is below zero then we return
		jl _string_to_int_return
		; gets the char at the index
		movzx r9, byte [rdi+r8]
		; converts the char to it's decimal value because it's ASCII
		sub r9, 0x30
		; validates the input is a number from 1-9
		cmp r9, 0
		jl _string_to_int_return
		cmp r9, 9
		jg _string_to_int_return
		; sets the power as an argument to imul
		mov rax, r11
		; multiplies the decimal value by the power
		imul r9
		; adds the result to the overall result
		add r10, rax
		; sets 10 as the argument to imul
		mov rax, 10
		; multiplies the current power by 10 (gets the next power)
		imul r11
		; sets the power as the result of the previous operation
		mov r11, rax
		; implicit jump to the top of the loop
		jmp _string_to_int_convert_loop
	_string_to_int_return:
		; returns the result
		mov rax, r10
		; restores the rdi register
		pop rdi
		; returns
		ret
	
	; the main entry point of the program
	; int __stdcall main(int argc, char *argv[])
	_main:
		; saves rdi
		push rdi
		; creates some stack space
		sub rsp, 0x410
	_main_input_loop:
		; adds the notification string
		lea rcx, [Notify]
		; notifies the user
		call printf
		; adds the format string an an argument
		lea rcx, [InputString]
		; adds the buffer as the second argument
		lea rdx, [rsp+0x104]
		; gets the users input
		call scanf
		; messy fix to clear the input buffer
		; adds the format string an an argument
		lea rcx, [ClearInput]
		; adds a temp buffer as the second argument
		lea rdx, [rsp]
		; clears the newline in the buffer
		call scanf
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the add string as an argument
		lea rdx, [Addition]
		; attempts to find the string within the users
		call _string_find
		; checks if add was found
		cmp eax, -1
		; jumps to the add section
		jne _main_add
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the subtract string as an argument
		lea rdx, [Subtract]
		; attempts to find the string within the users
		call _string_find
		; checks if subtract was found
		cmp eax, -1
		; jumps to the subtract section
		jne _main_subtract
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the multiply string as an argument
		lea rdx, [Multiply]
		; attempts to find the string within the users
		call _string_find
		; checks if multiply was found
		cmp eax, -1
		; jumps to the multiply section
		jne _main_multiply
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the divide string as an argument
		lea rdx, [Divide]
		; attempts to find the string within the users
		call _string_find
		; checks if divide was found
		cmp eax, -1
		; jumps to the divide section
		jne _main_divide
		; returns from the function
		jmp _main_input_loop
	_main_add:
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the addition string as an argument
		lea rdx, [Addition]
		; adds the first output string buffer
		lea r8, [rsp+0x208]
		; adds the second output string buffer
		lea r9, [rsp+0x30C]
		; splits the string
		call _string_split
		; adds the first output string as an argument
		lea rcx, [rsp+0x208]
		; converts the first string to an int
		call _string_to_int
		; saves the result
		mov rdi, rax
		; adds the second string as an argument
		lea rcx, [rsp+0x30C]
		; converts the second string to an int
		call _string_to_int
		; adds the two values
		add rdi, rax
		; jumps to the print
		jmp _main_print
	_main_subtract:
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the divide string as an argument
		lea rdx, [Subtract]
		; adds the first output string buffer
		lea r8, [rsp+0x208]
		; adds the second output string buffer
		lea r9, [rsp+0x30C]
		; splits the string
		call _string_split
		; adds the first output string as an argument
		lea rcx, [rsp+0x208]
		; converts the first string to an int
		call _string_to_int
		; saves the result
		mov rdi, rax
		; adds the second string as an argument
		lea rcx, [rsp+0x30C]
		; converts the second string to an int
		call _string_to_int
		; subtracts the two values
		sub rdi, rax
		; jumps to the print
		jmp _main_print
	_main_multiply:
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the divide string as an argument
		lea rdx, [Multiply]
		; adds the first output string buffer
		lea r8, [rsp+0x208]
		; adds the second output string buffer
		lea r9, [rsp+0x30C]
		; splits the string
		call _string_split
		; adds the first output string as an argument
		lea rcx, [rsp+0x208]
		; converts the first string to an int
		call _string_to_int
		; saves the result
		mov rdi, rax
		; adds the second string as an argument
		lea rcx, [rsp+0x30C]
		; converts the second string to an int
		call _string_to_int
		; multiplies the two values
		imul rdi
		; moves the result back to rdi
		mov rdi, rax
		; jumps to the print
		jmp _main_print
	_main_divide:
		; adds the users input as an argument
		lea rcx, [rsp+0x104]
		; adds the divide string as an argument
		lea rdx, [Divide]
		; adds the first output string buffer
		lea r8, [rsp+0x208]
		; adds the second output string buffer
		lea r9, [rsp+0x30C]
		; splits the string
		call _string_split
		; adds the first output string as an argument
		lea rcx, [rsp+0x208]
		; converts the first string to an int
		call _string_to_int
		; saves the result
		mov rdi, rax
		; adds the second string as an argument
		lea rcx, [rsp+0x30C]
		; converts the second string to an int
		call _string_to_int
		; saves the result
		mov rcx, rax
		; sets the numerator
		mov rax, rdi
		; divides the two values
		idiv rcx
		; moves the result back to rdi
		mov rdi, rax
		; jumps to the print
		jmp _main_print
	_main_print:
		; adds the format string as an argument
		mov rcx, FormatString
		; adds the original question as an argument
		lea rdx, [rsp+0x104]
		; adds the result as an argument
		mov r8, rdi
		; prints the result
		call printf
		; goes to the top of the input loop
		jmp _main_input_loop
	_main_return:
		; restores the stack
		add rsp, 0x410
		; restores rdi
		pop rdi
		; exits the program
		ret