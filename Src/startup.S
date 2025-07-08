@ ==========================================================================
@ ==========================================================================
@ Target: STM32F446 (Cortex-M4)
@
@ Blinks LED on PA5 (Nucleo-F446RE) every second using SysTick interrupt
@ Global variables: toggle led "toggle_LED" and "seconds_since_start" as counter
@ Toggles LED high for even seconds, low for odd seconds.
@ Function "control_led" is called in interrupt with arguments and returns
@ ==========================================================================
@ ==========================================================================

@ Directives to specify architecture and instruction set
.syntax unified                @ Use unified assembly syntax (ARM/Thumb compatible)
.cpu cortex-m4                 @ Target Cortex-M4
.fpu softvfp                   @ Use software floating-point (no FPU hardware)
.thumb                         @ Use Thumb instruction set for Cortex-M4

@ Global Symbols: Define entry points and stack top
.global Reset_Handler          @ Make Reset_Handler visible to linker
.global _estack                @ Make stack top address visible to linker
.global control_led            @ This line makes control_led function visible

@ Vector Table: Define interrupt service routine addresses
.section .isr_vector, "a", %progbits
.word _estack                  @ Initial Stack Pointer (top of stack)
.word Reset_Handler            @ Reset Handler (entry point after reset)
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word 0                        @ Reserved
.word SysTick_Handler          @ SysTick Handler (called every 1 second)

@ Data Section: Define 2 initialized variables
.section .data
.align 2                       @ Align to 4-byte boundary for uint32_t
toggle_LED:                    @ Boolean variable to signal LED toggle
.word 0                        @ Initialize to 0 (false)
seconds_since_start:           @ Counter for seconds elapsed
.word 0                        @ Initialize to 0

@ Reset Handler: Main entry point after processor reset
.section .text.Reset_Handler, "ax", %progbits
.type Reset_Handler, %function
Reset_Handler:
ldr sp, =_estack           @ Load stack pointer with address of stack top (_estack)

@ For clock, no HSE or PLL configuration needed. Nucleo-F446RE defaults to 16 MHz HSI clock
@ Configure Flash Latency for 16 MHz operation
ldr r0, =0x40023C00        @ Load base address of FLASH peripheral
ldr r1, [r0, #0x00]        @ Read FLASH_ACR
orr r1, #1                 @ Set bit 0 (LATENCY) for 1 wait state
str r1, [r0, #0x00]        @ Write back to FLASH_ACR

@ Enable GPIOA Clock
ldr r0, =0x40023830        @ Load address of RCC_AHB1ENR
ldr r1, [r0]               @ Read current value
orr r1, #1                 @ Set bit 0 (GPIOAEN)
str r1, [r0]               @ Write back to RCC_AHB1ENR

@ Configure PA5 as Output (for LED LD2)
ldr r0, =0x40020000        @ Load base address of GPIOA
ldr r1, [r0, #0x00]        @ Read GPIOA_MODER
orr r1, #1 << 10           @ Set bit 10 (PA5 mode bit 0) for output mode
bic r1, #1 << 11           @ Clear bit 11 (PA5 mode bit 1) to ensure mode 01
str r1, [r0, #0x00]        @ Write back to GPIOA_MODER
ldr r1, [r0, #0x04]        @ Read GPIOA_OTYPER
bic r1, #1 << 5            @ Clear bit 5 (PA5) for push-pull output
str r1, [r0, #0x04]        @ Write back to GPIOA_OTYPER
ldr r1, [r0, #0x08]        @ Read GPIOA_OSPEEDR
orr r1, #3 << 10           @ Set bits 10-11 (PA5) for high speed
str r1, [r0, #0x08]        @ Write back to GPIOA_OSPEEDR
ldr r1, [r0, #0x0C]        @ Read GPIOA_PUPDR
bic r1, #3 << 10           @ Clear bits 10-11 (PA5) for no pull-up/pull-down
str r1, [r0, #0x0C]        @ Write back to GPIOA_PUPDR

@ Configure SysTick for 1-Second Interrupts
ldr r0, =0xE000E010        @ Load base address of SysTick
ldr r1, =16000000 - 1      @ Set reload value for 1 second at 16 MHz
str r1, [r0, #0x04]        @ Write to SYST_RVR
mov r1, #0                 @ Clear current counter value
str r1, [r0, #0x08]        @ Write to SYST_CVR
mov r1, #7                 @ Enable SysTick, interrupt, and processor clock
str r1, [r0, #0x00]        @ Write to SYST_CSR

@ Initialize Variables
ldr r0, =toggle_LED        @ Load address of toggle_LED
mov r1, #0                 @ Set to 0 (false)
str r1, [r0]               @ Store to toggle_LED
ldr r0, =seconds_since_start @ Load address of seconds_since_start
mov r1, #0                 @ Set to 0
str r1, [r0]               @ Store to seconds_since_start

@ Enable Interrupts Globally
cpsie i                    @ Clear PRIMASK to enable interrupts

@ Main Loop
loop:
ldr r0, =toggle_LED        @ Load address of toggle_LED
ldr r1, [r0]               @ Read toggle_LED value
cmp r1, #1                 @ Check if true (1)
bne skip                   @ If not true, skip
mov r1, #0                 @ Reset toggle_LED to false
str r1, [r0]               @ Store back to toggle_LED
ldr r0, =seconds_since_start @ Load address of seconds_since_start
ldr r0, [r0]               @ Load value into r0
bl control_led             @ Call control_led with seconds_since_start
ldr r1, =seconds_since_start @ Load address of seconds_since_start
str r0, [r1]               @ Store returned value
skip:
wfi                        @ Wait For Interrupt
b loop                     @ Branch back to loop

@ SysTick Handler: Sets toggle_LED to true
.section .text.SysTick_Handler, "ax", %progbits
.type SysTick_Handler, %function
SysTick_Handler:
push {r4, lr}              @ Save r4 and LR
ldr r0, =toggle_LED        @ Load address of toggle_LED
mov r1, #1                 @ Set to true (1)
str r1, [r0]               @ Store to toggle_LED
pop {r4, pc}               @ Restore r4 and return

@ control_led Function: Sets PA5 based on seconds_since_start parity
@ Input: r0 (seconds_since_start)
@ Output: r0 (updated seconds_since_start)
.section .text.control_led, "ax", %progbits
.type control_led, %function
control_led:
push {r4, lr}              @ Save r4 and LR
mov r4, r0                 @ Save input to r4
ldr r1, =0x40020000        @ Load GPIOA base address
ldr r2, [r1, #0x14]        @ Read GPIOA_ODR
and r3, r4, #1             @ Check LSB for parity (0 = even, 1 = odd)
cmp r3, #0                 @ Compare with 0
beq set_high               @ If even, set PA5 high
bic r2, #1 << 5            @ Clear bit 5 (PA5 low)
str r2, [r1, #0x14]        @ Write to GPIOA_ODR
b done
set_high:
orr r2, #1 << 5            @ Set bit 5 (PA5 high)
str r2, [r1, #0x14]        @ Write to GPIOA_ODR
done:
add r0, r4, #1             @ Increment seconds_since_start
pop {r4, pc}               @ Restore r4 and return
.size control_led, .-control_led

@ Stack Section: Reserve space for stack
.section .stack, "aw", %nobits
.space 0x400               @ Reserve 1 KB for stack
_estack:
@end
