
// kalman.s

/**
Assembler directives
*/

/**
The "unified" syntax option tells the assembler to interpret 
ARM and THUMB instructions in the same file, without the programmer
having to specify which set the instruction is from.
*/
.syntax unified

/**
The "align" directive ensures 16-byte alignment for all code.
*/
.align 16

/**
The "text" directive instructs the assembler to place the function into
the read-only memory, since the code itself is not going to change.
*/
.section .text, "x" //as.pdf :p96

/**
This allows the linker to use the "kalman" label in main.c without needing to
import this file.
*/
.global kalman //as.pdf : p254

/**
 * @brief Update function for the Kalman filter. The function changes the filter
 * parameters in place and returns nothing. 
 * 
 * @param filter1 : Pointer to a KalmanFilter struct
 * @param measurement : The newest measurement to update the filter coefficients
 * 
 * [Register mapping]

 * [Input arguments]
 * R0 => Pointer to the Kalman filter struct. This instance will be modified in
 * place.
 * S0 => The latest measurement value with which the filter coefficients will be
 * updated.

 * [Kalman filter parameters] 
 * S1 => Process noise covariance (q)
 * S2 => Measurement noise covariance (r)
 * S3 => Estimated value (x)
 * S4 => Estimation error covariance (p)
 * S5 => Adaptive Kalman filter gain (k)
 * S7 => Temporary register for intermediate values
 */
kalman:
//PUSH current state to stack
//TODO: #1 Test before lab
// PUSH {R1-LR}
// VPUSH.F32 {S8-S31}

// Load the filter parameters into the registers described above
VLDM.F32 R0, {S1-S5}

// p = p + q
VADD.F32 S4, S4, S1

// With S7 = (p + r),
// k = p / S7
// Tried to play with the equation to avoid the DIV, could not
// find a way. Any tips?
VADD.F32 S7, S4, S2
VDIV.F32 S5, S4, S7

// With S7 = measurement(=S0) - x (=S3),
// x = x + k * S7; refactored into an MLA
VSUB.F32 S7, S0, S3
VMLA.F32 S3, S5, S7

// p = (1 - k) * p
// p = p - p*k; refactored into a single MLS
VMLS.F32 S4, S4, S5

// Check the first 5 bits of FPSCR to see if an 
// exception has occured in the operations.
// TODO: #4 Test before lab
// MRS R1, FPSCR
// TST R1, #0x1F
// Clear exception bits if exception did happen
// BICNE R1, R1, #0x1F
// MSRNE FPSCR, R1
// BNE exit

// If no exception occured, update filter coefficients in place
VSTM.F32 R0, {S1-S5}

exit:
//POP stack (and clear FPSCR)
// TODO: #3 Test before lab
// POP {R1-LR}
// VPOP.F32 {S8-S31}
    BX LR



