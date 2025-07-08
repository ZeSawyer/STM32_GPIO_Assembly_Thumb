Objective: 
- In STM32CubeIDE, write a basic assembly code to run on a startup file of STM32F44
- No use of main.c file 
- The application should blink LED on PA5 every second using SysTick interrupt
- Global variables used: toggle led "toggle_LED" and "seconds_since_start" as counter
- LED is set high on even seconds, low for odd seconds.
- Function "control_led" is called in interrupt with an argument to increment by 1, then return the new incremented value

Method: 
- Use Thumb instruction set
- Use SysTick to trigger an interrupt each one second
- Execute logic then wait for next interrupt

Result:
- The value of R0 and R1 (used in function arguments and returns) were noticed to increase each 1 second 
- The LED was toggled as expected
