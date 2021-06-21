BASE64D  TITLE 'Subroutine to decode Base64 data'
* ---------------------------------------------------------------------
*
* (C) Copyright IBM Corp. 2021
*
* ---------------------------------------------------------------------
*
* Parameters:
*
*    1 - Address of Base64-encoded data
*    2 - Address of length of input data as an unsigned fullword field
*    3 - Address of output buffer
*    4 - Address of fullword field containing the output buffer length
*        as an unsigned value.
*        On return code < 64, will contain the number of bytes written
*
* The input data area must only contain valid Base64-encoded data.
* This is defined by The Base64 Alphabet table in RFC 2045.
*
* When the entry point is BASE64D, the input characters must be
* encoded using an EBCDIC code page.
*
* The characters defined by the Base64 alphabet are invariant across
* all EBCDIC code pages, therefore it is not necessary to perform
* codepage conversion from one EBCDIC code page to another.
*
* When the entry point is BASE64DA, the input characters must be
* encoded using an ASCII code page.
*
* The characters defined by the Base64 alphabet are invariant across
* all ASCII code pages, therefore it is not necessary to perform
* codepage conversion from one ASCII code page to another.
*
* Padding is mandatory and the input data length must be a multiple of
* 4 bytes.
*
* The output data area must have at least 3 bytes for every 4 bytes
* provided on the input. If insufficient bytes are provided, then
* the routine will encode as many complete 4-byte groups as can fit
* into the output buffer and will return a truncated return code.
*
* Input and output data buffers do not need any special alignment.
* Data is manipulated character-wise.
*
* If the input and output data buffers overlap, the results are
* undefined.
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
*   76 : Input data length not a multiple of 4
*   80 : Output data address was null
*   84 : Output data length address was null
*   88 : Input data was not a valid Base64 encoding
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
*   R10 : Number of padding characters found
*   R11 : Address of parameter list
*   R12 :
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
BASE64D  CSECT ,
BASE64D  AMODE 31
BASE64D  RMODE 31
         SAVE  (14,12)             Save callers registers
         LARL  R9,Table64          Setup address of translate table
         J     Common
*
         ENTRY BASE64DA
BASE64DA DS    0H
         SAVE  (14,12)             Save callers registers
         LARL  R9,Table64A         Setup address of translate table
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
* Validate input data length is multiple of 4 and save in R7
*----------------------------------------------------------------------
         DS    0H
         LT    R1,Parm_InLenAddr   Load input buffer len address
         JZ    InLenAddrNull       Should be non-zero
*
         LT    R7,0(R1)            Obtain supplied input length
         JZ    InLenZero           Should be non-zero
*
         LR    R4,R7               Take a copy
         NILF  R4,3                Keep only bottom 2 bits
         JNZ   InLenNotMult4       Multiples of 4 never have lo 2 bits
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
*
         LT    R2,0(R1)            Obtain supplied output length
*
         LR    R3,R7               Take a copy of input length
         SRL   R3,2                Divide by 4 to get number of
*                                  output triples we can fit in buffer
         MHI   R3,3                Multiply by 3 to get the number of
*                                  bytes we require to output
         CRJNH R3,R2,OutLenOK      OK if required len <= output len
*
         LHI   R15,RC_Truncated    We will truncate the output
         LR    R3,R2               Take a copy of the output length
         LHI   R2,0                Clear hi part of dividend
         LHI   R0,3                Divide by 3
         D     R2,R0
         SLL   R3,2                Multiply quotient by 4
         LR    R7,R3               Update input length
*
OutLenOK DS    0H
         EJECT ,
*----------------------------------------------------------------------
* Setup ready for main loop
*----------------------------------------------------------------------
         DS    0H
         LHI   R10,0               Clear number of padding chars found
*
*----------------------------------------------------------------------
* Main decode loop
*    Input is validated to be a multiple of 4 bytes and we only read
*    in multiples of 4, so only need to test for zero.
*----------------------------------------------------------------------
MainLoop DS    0H
         CIJE  R7,0,LoopEnd        Have we read all the bytes?
         CIJNE R10,0,DataNotValid  More data, but already had pad?
*
*----------------------------------------------------------------------
* Load 4 characters from input and save in R2
*----------------------------------------------------------------------
         DS    0H
         ICM   R2,B'1111',0(R5)    Load next 4 characters
         LA    R5,4(R5)            Point to next 4 characters
         SLFI  R7,4                4 characters have been read
         EJECT ,
*----------------------------------------------------------------------
* Take data in R2 and decode, save as low 24 bits in R4. Mostly
* achieved by the ROTATE THEN INSERT SELECTED BITS LOW instruction.
*
*   RISBLG R1,R2,56,X'80'+63,-24
*
* Takes contents of R2, rotates right by 24 bits, stores bits 56
* through 63 into R1 and zeroes remaining bits (X'80' flag).
*
* The extracted 8-bit value in R1 is then used as an index into the
* translation table addressed by R9.
*
* The translation table converts the EBCDIC/ASCII character encoding
* value into a number 0-63 which represents the bit pattern of that
* character in the Base64 index table.
*
* From that value in the Base64 index table, we can take those decoded
* 4 sets of 6 bits and accumulate them in R4, one input byte at a time,
* forming 3 output bytes of 8 bits each.
*
*----------------------------------------------------------------------
         LHI   R4,0                Clear target reg
*
* ------ Byte 1
         RISBLG R1,R2,56,X'80'+63,-24   Work on top byte
         LLC   R3,0(R1,R9)         Get correct bit pattern from table
*
         CIJE  R3,BadChar,DataNotValid   Branch if not valid character
*
         CIJE  R3,PadChar,DataNotValid   Not valid to have pad here
*
         ROSBG R4,R3,40,45,18      Shift R3 18 left then OR into R4
*
* ------ Byte 2
         RISBLG R1,R2,56,X'80'+63,-16   Work on 2nd byte
         LLC   R3,0(R1,R9)         Get correct bit pattern from table
*
         CIJE  R3,BadChar,DataNotValid   Branch if not valid character
*
         CIJE  R3,PadChar,DataNotValid   Not valid to have pad here
*
         ROSBG R4,R3,46,51,12      Shift R3 12 left then OR into R4
*
* ------ Byte 3
         RISBLG R1,R2,56,X'80'+63,-8    Work on 3rd byte
         LLC   R3,0(R1,R9)         Get correct bit pattern from table
*
         CIJE  R3,BadChar,DataNotValid   Branch if not valid character
*
         CIJE  R3,PadChar,Pad3     Padding character?
*
         ROSBG R4,R3,52,57,6       Shift R3 6 left then OR into R4
         J     Pad3Skip
*
Pad3     AHI   R10,1               Padding is valid here
Pad3Skip DS    0H
*
* ------ Byte 4
         RISBLG R1,R2,56,X'80'+63  Work on 4th byte
         LLC   R3,0(R1,R9)         Get correct bit pattern from table
*
         CIJE  R3,BadChar,DataNotValid   Branch if not valid character
*
         CIJE  R3,PadChar,Pad4     Padding character?
*
         CIJNE R10,0,DataNotValid  Error if padding, then non-padding
*
         ROSBG R4,R3,58,63         OR lo 6 bits into R4
         J     Pad4Skip
*
Pad4     AHI   R10,1               Padding is valid here
Pad4Skip DS    0H
*
*----------------------------------------------------------------------
* Take low 24-bits in R4 and write as up to 3 bytes.
* Bytes are extracted from R4 using RISBLG and a similar process as
* that described above.
*----------------------------------------------------------------------
         DS    0H                  Always write first byte
         RISBLG R3,R4,56,63,-16    1st byte in triple
         STC   R3,0(R8,R6)         Save byte
*
         DS    0H                  Write second byte if not padding
         CIJE  R10,2,WriteEnd      Skip if two bytes of padding
         RISBLG R3,R4,56,63,-8     2nd byte in triple
         STC   R3,1(R8,R6)         Save byte
*
         DS    0H                  Write third byte if not padding
         CIJE  R10,1,WriteEnd      Skip if one byte of padding
         RISBLG R3,R4,56,63        3rd byte in triple
         STC   R3,2(R8,R6)         Save byte
*
*----------------------------------------------------------------------
* End of main decode loop
*----------------------------------------------------------------------
WriteEnd DS    0H
         AFI   R8,3                Three more bytes written
         SR    R8,R10              Minus the number of padding bytes
         J     MainLoop            Loop start will test for remaining
*
*----------------------------------------------------------------------
* Exit of main loop
*----------------------------------------------------------------------
LoopEnd  DS    0H
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
DecodeEnd DS   0H
         RETURN (14,12),RC=(15)    Return to caller with RC in R15
         EJECT ,
*----------------------------------------------------------------------
* Labels to handle bad input data return codes
*----------------------------------------------------------------------
InAddrNull DS  0H
         LHI   R15,RC_InAddrNull
         J     DecodeEnd
*
InLenAddrNull DS 0H
         LHI   R15,RC_InLenAddrNull
         J     DecodeEnd
*
InLenZero DS   0H
         LHI   R15,RC_InLenZero
         J     DecodeEnd
*
InLenNotMult4 DS 0H
         LHI   R15,RC_InLenNotMult4
         J     DecodeEnd
*
OutAddrNull DS 0H
         LHI   R15,RC_OutAddrNull
         J     DecodeEnd
*
OutLenAddrNull DS 0H
         LHI   R15,RC_OutLenAddrNull
         J     DecodeEnd
*
DataNotValid DS 0H
         LHI   R15,RC_InputDataNotValid
         J     DecodeEnd
*
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
RC_InLenNotMult4        EQU  76
RC_OutAddrNull          EQU  80
RC_OutLenAddrNull       EQU  84
RC_InputDataNotValid    EQU  88
*
* Table to convert from Base64 using an EBCDIC codepage
Table64  DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       00-0F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       10-1F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       20-2F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       30-3F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F3E7F'       40-4F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       50-5F
         DC    XL16'7F3F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       60-6F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F407F'       70-7F
         DC    XL16'7F1A1B1C1D1E1F2021227F7F7F7F7F7F'       80-8F
         DC    XL16'7F232425262728292A2B7F7F7F7F7F7F'       90-9F
         DC    XL16'7F7F2C2D2E2F303132337F7F7F7F7F7F'       A0-AF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       B0-BF
         DC    XL16'7F0001020304050607087F7F7F7F7F7F'       C0-CF
         DC    XL16'7F090A0B0C0D0E0F10117F7F7F7F7F7F'       D0-DF
         DC    XL16'7F7F12131415161718197F7F7F7F7F7F'       E0-EF
         DC    XL16'3435363738393A3B3C3D7F7F7F7F7F7F'       F0-FF
*
* Table to convert from Base64 using as ASCII codepage
Table64A DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       00-0F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       10-1F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F3E7F7F7F3F'       20-2F
         DC    XL16'3435363738393A3B3C3D7F7F7F407F7F'       30-3F
         DC    XL16'7F000102030405060708090A0B0C0D0E'       40-4F
         DC    XL16'0F101112131415161718197F7F7F7F7F'       50-5F
         DC    XL16'7F1A1B1C1D1E1F202122232425262728'       60-6F
         DC    XL16'292A2B2C2D2E2F303132337F7F7F7F7F'       70-7F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       80-8F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       90-9F
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       A0-AF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       B0-BF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       C0-CF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       D0-DF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       E0-EF
         DC    XL16'7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F'       F0-FF
*
PadChar  EQU   X'40'               Padding character value in tables
BadChar  EQU   X'7F'               Invalid character value in tables
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
         END   BASE64D
         END   ,