BASE64E  TITLE 'Subroutine to Base64 encode data'
* ---------------------------------------------------------------------
*
* (C) Copyright IBM Corp. 2021
*
* ---------------------------------------------------------------------
*
* Parameters:
*
*    1 - Address of data for conversion to Base64
*    2 - Address of length of input data as an unsigned fullword field
*    3 - Address of output buffer
*    4 - Address of fullword field containing the output buffer length
*        as an unsigned value.
*        On return code < 64, will contain the number of bytes written
*
* The output data area must have at least 4 bytes for every 3 bytes
* provided on the input. If insufficient bytes are provided, then
* the routine will encode as many complete 3-byte groups as can fit
* into the output buffer and will return a truncated return code.
*
* Input and output data buffers do not need any special alignment.
* Data is manipulated character-wise.
*
* If the input and output data buffers overlap, the results are
* undefined.
*
* The output data uses the characters defined by The Base64 Alphabet
* table in RFC 2045.
*
* When the entry point is BASE64E, the output characters are encoded
* using an EBCDIC code page.
*
* The characters defined by the Base64 alphabet are invariant across
* all EBCDIC code pages, therefore it is not necessary to perform
* codepage conversion from one EBCDIC code page to another.
*
* When the entry point is BASE64EA, the output characters are encoded
* using an ASCII code page. This output is suitable for transmission
* directly to a non-Z platform without any intermediate code page
* conversion.
*
* The characters defined by the Base64 alphabet are invariant across
* all ASCII code pages, therefore it is not necessary to perform
* codepage conversion from one ASCII code page to another.
*
* ---------------------------------------------------------------------
*
* The following registers should be set on entry:
*
*  R1  = Address of standard parameter list
*  R13 = Address of 72-byte save area
*  R14 = Branch return address
*
* On exit, the registers will be set as follows:

*  R0-R14 : (unchanged)
*  R15    : Return code
*
* This routine is rentrant
*
* ---------------------------------------------------------------------
*
* Return codes:
*    0 : Success
*
* Warnings:
*    4 : Data was truncated
*
* Errors:
*   64 : Input data address was null
*   68 : Input data length address was null
*   72 : Input data length was zero
*   76 : Output data address was null
*   80 : Output data length address was null
*
* ---------------------------------------------------------------------
*
* Register usage:
*
*   R0  :
*   R1  : <work register>
*   R2  : <work register>
*   R3  : <work register>
*   R4  : <work register>
*   R5  : Address of next input byte
*   R6  : Address of first output byte
*   R7  : Input bytes remaining
*   R8  : Bytes written
*   R9  : Address of translation table
*   R10 : Number of padding bytes needed
*   R11 : Address of parameter list
*   R12 : Padding character in relevant output encoding
*   R13 : Callers save area
*   R14 :
*   R15 : Return code
*
* Routine uses relative addressing, so no CSECT USING required.
*
*----------------------------------------------------------------------
*
* Compilation notes:
*
*   Requires a minimum of OPTABLE(ZS4)
*
*----------------------------------------------------------------------
         EJECT ,
*----------------------------------------------------------------------
* Setup addressability
*----------------------------------------------------------------------
BASE64E  CSECT ,
BASE64E  AMODE 31
BASE64E  RMODE 31
         SAVE  (14,12)             Save callers registers
         LARL  R9,Table64          Setup address of translate table
         LHI   R12,PadChar         Padding character in EBCDIC
         J     Common
*
         ENTRY BASE64EA
BASE64EA DS    0H
         SAVE  (14,12)             Save callers registers
         LARL  R9,Table64A         Setup address of translate table
         LHI   R12,PadCharA        Padding character in ASCII
         J     Common
*
*----------------------------------------------------------------------
* Program setup
*----------------------------------------------------------------------
Common   DS    0H
         LR    R11,R1
         USING PARMLIST,R11        Parmlist addressability
         LHI   R8,0                Zero bytes written
         LHI   R15,RC_Success      Explicit set of return code
         EJECT ,
*----------------------------------------------------------------------
* Validate input data address and save in R5
*----------------------------------------------------------------------
         DS    0H
         LT    R5,Parm_InAddr      Load address of input buffer
         JZ    InAddrNull          Should be non-zero
*
*----------------------------------------------------------------------
* Validate input data length and save in R7
*----------------------------------------------------------------------
         DS    0H
         LT    R1,Parm_InLenAddr   Load input buffer len address
         JZ    InLenAddrNull       Should be non-zero
*
         LT    R7,0(R1)            Obtain supplied input length
         JZ    InLenZero           Should be non-zero
*
*----------------------------------------------------------------------
* Validate output data buffer address and save in R6
*----------------------------------------------------------------------
         DS    0H
         LT    R6,Parm_OutAddr     Load address of output buffer
         JZ    OutAddrNull         Should be non-zero
*
*----------------------------------------------------------------------
* Validate output data buffer length: possibly update R7
*----------------------------------------------------------------------
         DS    0H
         LT    R1,Parm_OutLenAddr  Load address of output buffer len
         JZ    OutLenAddrNull      Should be non-zero
         L     R2,0(R1)            Get the output length
         SRL   R2,2                Divide by 4 to get number of
*                                  input triples we can fit in buffer
         MHI   R2,3                Multiply by 3 to get the number of
*                                  equivalent bytes from the input
         CRJNL R2,R7,OutLenOK      OK if capacity >= input length
*
         LHI   R15,RC_Truncated    We will truncate the output
         LR    R7,R2               R2 is multiple of 3: therefore we
*                                  will avoid processing partial triple
*                                  if we use this many input bytes
*
OutLenOK DS    0H
         EJECT ,
*----------------------------------------------------------------------
* Main encoding loop
*----------------------------------------------------------------------
MainLoop DS    0H
         LHI   R2,0                Clear work register
         LHI   R10,0               Clear padding byte count
*
*----------------------------------------------------------------------
* How many bytes are remaining?
*----------------------------------------------------------------------
         CIJE  R7,0,PadNone        Finished?
         CIJE  R7,1,Rem1           Exactly one remaining?
         CIJE  R7,2,Rem2           Exactly two remaining?
         J     Rem3                At least 3 remaining
*
         EJECT ,
*----------------------------------------------------------------------
* Read data from storage into R2, setting R10 to padding count
*----------------------------------------------------------------------
Rem1     DS    0H                  Exactly 1 char remaining
         ICM   R2,B'1000',0(R5)    Load next character
         LHI   R10,2               Need 2 bytes of padding
         SLFI  R7,1                Final character has been read
         J     DoOutput
*
Rem2     DS    0H                  Exactly 2 chars remaining
         ICM   R2,B'1100',0(R5)    Load next 2 characters
         LHI   R10,1               Need 1 byte of padding
         SLFI  R7,2                Final 2 characters have been read
         J     DoOutput
*
Rem3     DS    0H                  At least 3 chars remaining
         ICM   R2,B'1110',0(R5)    Load next 3 characters
         SLFI  R7,3                3 characters have been read
         LA    R5,3(R5)            Point to next 3 characters
         J     DoOutput
*
         EJECT ,
*----------------------------------------------------------------------
* Take data from R2, convert, and write to storage. Mostly achieved
* by the ROTATE THEN INSERT SELECTED BITS LOW instruction.
*
*   RISBLG R3,R2,58,X'80'+63,-26
*
* Takes contents of R2, rotates right by 26 bits, stores bits 58
* through 63 into R3 and zeroes remaining bits (X'80' flag).
*
* The extracted 6-bit value in R3 is then used as an index into the
* translation table addressed by R9.
*----------------------------------------------------------------------
DoOutput DS    0H
*                              Write first char (always needed)
         RISBLG R3,R2,58,X'80'+63,-26  Hi 6 bits of #1
         LLC   R4,0(R3,R9)         Get correct character from table
         STC   R4,0(R8,R6)         Save char at offset 0
*
*                              Write second char (always needed)
         RISBLG R3,R2,58,X'80'+63,-20  Lo 2 bits of #1, hi 4 bits of #2
         LLC   R4,0(R3,R9)         Get correct character from table
         STC   R4,1(R8,R6)         Save char at offset 1
*
*                              Write third char (may skip to pad)
         CIJE  R10,2,PadTwo        Two bytes of padding needed?
         RISBLG R3,R2,58,X'80'+63,-14  Lo 4 bits of #2, hi 2 bits of #3
         LLC   R4,0(R3,R9)         Get correct character from table
         STC   R4,2(R8,R6)         Save char at offset 2
*
*                              Write fourth char (may skip to pad)
         CIJE  R10,1,PadOne        One byte of padding needed?
         RISBLG R3,R2,58,X'80'+63,-8   Only keep lo 6 bits of #3
         LLC   R4,0(R3,R9)         Get correct character from table
         STC   R4,3(R8,R6)         Save char at offset 3
*
         AFI   R8,4                Four more bytes written
         J     MainLoop            Loop start will test for remaining
*
         EJECT ,
*----------------------------------------------------------------------
* Write padding characters where needed
*----------------------------------------------------------------------
PadTwo   STC   R12,2(R8,R6)        Padding char at offset 2
PadOne   STC   R12,3(R8,R6)        Padding char at offset 3
         AFI   R8,4                4 more bytes written incl. padding
*
PadNone  DS    0H                  Target out of loop for no padding
         EJECT ,
*----------------------------------------------------------------------
* Save bytes written to user area
*----------------------------------------------------------------------
         DS    0H
         L     R2,Parm_OutLenAddr  Load address of output buffer len
         ST    R8,0(R2)            Save number of bytes written
*
*----------------------------------------------------------------------
* Terminate program
*----------------------------------------------------------------------
EncodeEnd DS   0H
         RETURN (14,12),RC=(15)    Return to caller with RC in R15
         EJECT ,
*----------------------------------------------------------------------
* Labels to handle bad input data return codes
*----------------------------------------------------------------------
InAddrNull DS  0H
         LHI   R15,RC_InAddrNull
         J     EncodeEnd
*
InLenAddrNull DS 0H
         LHI   R15,RC_InLenAddrNull
         J     EncodeEnd
*
InLenZero DS   0H
         LHI   R15,RC_InLenZero
         J     EncodeEnd
*
OutAddrNull DS 0H
         LHI   R15,RC_OutAddrNull
         J     EncodeEnd
*
OutLenAddrNull DS 0H
         LHI   R15,RC_OutLenAddrNull
         J     EncodeEnd
         EJECT ,
*----------------------------------------------------------------------
* Clean up USINGs
*----------------------------------------------------------------------
         DROP  R11                 Parmlist
         EJECT ,
*----------------------------------------------------------------------
* Program constants and local statics
*----------------------------------------------------------------------
*
* Return code equates
RC_Success              EQU  0
RC_Truncated            EQU  4
RC_InAddrNull           EQU  64
RC_InLenAddrNull        EQU  68
RC_InLenZero            EQU  72
RC_OutAddrNull          EQU  76
RC_OutLenAddrNull       EQU  80
*
* Useful compilation constants
PadChar  EQU   C'='                Padding character for EBCDIC
PadCharA EQU   CA'='               Padding character for ASCII
*
* Table to convert to Base64 in EBCDIC encoding
* All these characters are invariant across all EBCDIC code pages,
* therefore the byte output of this program will remain constant
* regardless of the codepage used for the compiler.
Table64  DC    CL32'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
         DC    CL32'ghijklmnopqrstuvwxyz0123456789+/'
*
* Table to convert to Base64 in ASCII encoding
Table64A DC    CAL32'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
         DC    CAL32'ghijklmnopqrstuvwxyz0123456789+/'
*
         LTORG ,                   Generated literals go here
         EJECT ,
*----------------------------------------------------------------------
* Program parameter list
*----------------------------------------------------------------------
Parmlist        DSECT 0F
Parm_InAddr     DS A               Addr of input data (in)
Parm_InLenAddr  DS A               Addr of input data length (in)
Parm_OutAddr    DS A               Addr of output data (in)
Parm_OutLenAddr DS A               Addr of output data length (in/out)
         EJECT ,
*----------------------------------------------------------------------
* Register equates.
*----------------------------------------------------------------------
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
         EJECT ,
*----------------------------------------------------------------------
* End of program
*----------------------------------------------------------------------
         END   BASE64E
         END   ,
