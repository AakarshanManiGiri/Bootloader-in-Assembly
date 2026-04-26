# Minimal Bootloader
A bootloader written in assembly written in Assembly. This project is mainly a stepping stone to connect to a main project to code a OS in C++ (Minimal OS).
It fits in the first 512 bytes of memory on a bootable drive.

# Major Patch #1:
- **OS Direction**: The Os that connects to this project will be for a E-ink Reader, This is mostly because i want a e-reader with a ink display and i dont want to be utterly scammed by the prices of kindles right now. The OS will prolly just be super barebones, Current thought is just displaying pdfs which i can flip through using a button combination to skip to the next pdf with a continous scroll using the touch screen of the E-ink display i'm eyeing.

# How it works
When a computer starts, the BIOS (Basic Input/Output System) performs a hardware check and looks for a bootable device. It specifically looks for the Magic Boot Signature (0x55AA) in the final two bytes of the first sector.

- **Loading**: The BIOS loads this 512-byte binary into physical memory at address 0x7C00.

- **Environment**: The CPU starts in 16-bit Real Mode, providing direct access to BIOS interrupts and memory.

- **Execution**: This bootloader initializes the CPU registers, prints a greeting via video interrupts, and safely halts the processor.
