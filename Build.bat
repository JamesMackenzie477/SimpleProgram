REM Assembles the source file into a Windows 64-bit object file with NASM
NASM\nasm.exe -f win64 SimpleProgram.asm -o Release\SimpleProgram.obj
REM Links the Windows 64-bit object file into an executable application (linker_parameters.txt contains the linker parameters)
Golink\GoLink.exe @linker_parameters.txt