; BDIST.Z80 - BeanZee Entry Point and Hardware Functions
;
; Entry point for BBC BASIC Z80 on the BeanZee system.
; ROM boot at address 0x0000. Code in ROM (0x0000-0x7FFF),
; RAM at 0x8000-0xFFFF.
;
; Provides screen control and time functions required by
; the core interpreter (EXEC.Z80, EVAL.Z80).
;
; cf. DIST.Z80 (CP/M entry point)
;
    PUBLIC CLRSCN
    PUBLIC PUTCSR
    PUBLIC GETCSR
    PUBLIC PUTIME
    PUBLIC GETIME
;
    EXTERN START        ; MAIN.Z80 interpreter entry
    EXTERN OSWRCH       ; BMOS.Z80 character output
;
; Entry point - first instruction at 0x0000
;
    JP START            ; Jump to BASIC cold start
;
;CLRSCN - Clear screen.
;   Send VT100 escape sequence: ESC[2J ESC[H
;   Destroys: A,D,E,H,L,F
;
CLRSCN:
    LD A,1BH            ; ESC
    CALL OSWRCH
    LD A,'['
    CALL OSWRCH
    LD A,'2'
    CALL OSWRCH
    LD A,'J'
    CALL OSWRCH
    LD A,1BH            ; ESC
    CALL OSWRCH
    LD A,'['
    CALL OSWRCH
    LD A,'H'
    JP OSWRCH           ; Cursor home and return
;
;PUTCSR - Move cursor to specified position.
;   Inputs: DE = horizontal position (LHS=0)
;           HL = vertical position (TOP=0)
;   Destroys: A,D,E,H,L,F
;
PUTCSR:
    RET                 ; Not implemented
;
;GETCSR - Return cursor coordinates.
;   Outputs: DE = X coordinate (POS)
;            HL = Y coordinate (VPOS)
;   Destroys: A,D,E,H,L,F
;
GETCSR:
    LD DE,0
    LD HL,0
    RET
;
;PUTIME - Load elapsed-time clock.
;   Inputs: DEHL = time to load (centiseconds)
;   Destroys: A,D,E,H,L,F
;
PUTIME:
    RET                 ; No clock hardware
;
;GETIME - Read elapsed-time clock.
;   Outputs: DEHL = elapsed time (centiseconds)
;   Destroys: A,D,E,H,L,F
;
GETIME:
    LD DE,0
    LD HL,0
    RET
;
FIN:
