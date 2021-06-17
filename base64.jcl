//BASE64   JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,
//          REGION=0M,MEMLIMIT=1G
//*
//* (C) Copyright IBM Corp. 2021
//*
//         SET      HLQ=userid
//*
//         SET      ASM=&HLQ..SRC.ASM
//         SET        C=&HLQ..SRC.C
//         SET    COBOL=&HLQ..SRC.COBOL
//         SET      PLI=&HLQ..SRC.PLI
//*
//         SET     DEST=&HLQ..SRC.PROGLOAD
//*
//         SET      CEE=PP.ADLE370.ZOS204
//         SET    CCOMP=PP.CBC.ZOS204
//         SET  COBCOMP=PP.COBOL390.V630
//         SET  PLICOMP=PP.VAPLI.V530
//*
//********************************************************************
//* Procedure to compile an assembly application
//********************************************************************
//ASM      PROC
//COMPILE  EXEC PGM=ASMA90
//SYSLIB   DD DISP=SHR,DSN=SYS1.MACLIB
//         DD DISP=SHR,DSN=SYS1.MODGEN
//SYSIN    DD DISP=SHR,DSN=&ASM(&MEMBER)
//SYSLIN   DD DISP=(OLD,PASS),DSN=&&OBJECT(&MEMBER)
//SYSPRINT DD SYSOUT=*
//ASMAOPT  DD *
  LIST(133)
  OPTABLE(ZS4)
  RENT
/*
//         PEND
//*
//********************************************************************
//* Procedure to compile a COBOL application
//********************************************************************
//COBOL    PROC
//COMPILE  EXEC PGM=IGYCRCTL,PARM='OPTFILE'
//STEPLIB  DD DISP=SHR,DSN=&COBCOMP..SIGYCOMP
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT8   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT9   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT10  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT11  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT12  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT13  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT14  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT15  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSMDECK DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSIN    DD DISP=SHR,DSN=&COBOL(&MEMBER)
//SYSLIN   DD DISP=(OLD,PASS),DSN=&&OBJECT(&MEMBER)
//SYSPRINT DD SYSOUT=*
//SYSOPTF  DD *
   ARCH(11)
   MAP
   OPTIMIZE(2)
   RENT
/*
//         PEND
//*
//********************************************************************
//* Procedure to compile a C application
//********************************************************************
//C        PROC
//COMPILE  EXEC PGM=CCNDRVR,PARM='OPTFILE'
//STEPLIB  DD DISP=SHR,DSN=&CCOMP..SCCNCMP
//SYSUT5   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT8   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT9   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT14  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT16  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT17  DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSIN    DD DISP=SHR,DSN=&C(&MEMBER)
//SYSLIN   DD DISP=(OLD,PASS),DSN=&&OBJECT(&MEMBER)
//SYSLIB   DD DISP=SHR,DSN=&CEE..SCEEH.H
//         DD DISP=SHR,DSN=&CEE..SCEEH.SYS.H
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSCPRT  DD SYSOUT=*
//SYSOPTF  DD *
  ARCH(11)
NOMARGINS
  OPTIMIZE(2)
  RENT
NOSEQUENCE
  SOURCE
/*
//         PEND
//*
//********************************************************************
//* Procedure to compile a PL/I application
//********************************************************************
//PLI      PROC
//COMPILE  EXEC PGM=IBMZPLI,PARM='+DD:OPTIONS'
//STEPLIB  DD DISP=SHR,DSN=&PLICOMP..SIBMZCMP
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSIN    DD DISP=SHR,DSN=&PLI(&MEMBER)
//SYSLIN   DD DISP=(OLD,PASS),DSN=&&OBJECT(&MEMBER)
//SYSPRINT DD SYSOUT=*
//OPTIONS  DD *
  ARCH(11)
  MAP
  OPTIMIZE(2)
  OPTIONS
  RENT
  SOURCE
  XREF
/*
//         PEND
//*
//********************************************************************
//* Procedure to linkedit an application
//********************************************************************
//LINKEDIT PROC
//BINDER   EXEC PGM=IEWL
//SYSLMOD  DD DISP=SHR,DSN=&DEST
//OBJLIB   DD DISP=(OLD,PASS),DSN=&&OBJECT
//SYSLIB   DD DISP=SHR,DSN=&CEE..SCEELKED
//         DD DISP=SHR,DSN=SYS1.LINKLIB
//SYSPRINT DD SYSOUT=*
//IEWPARMS DD *
AMODE=31
MAP
REUS=RENT
RMODE=31
/*
//         PEND
//*
//********************************************************************
//* Procedure to run an application
//********************************************************************
//RUN      PROC
//GO       EXEC PGM=&MEMBER
//STEPLIB  DD DISP=SHR,DSN=&DEST
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//         PEND
//*
//********************************************************************
//* Establish a temporary PDSE
//********************************************************************
//DEFINE   EXEC PGM=IEFBR14
//OBJECT   DD DISP=(NEW,PASS),DSN=&&OBJECT,
//          UNIT=SYSALLDA,SPACE=(CYL,(1,1,1)),
//          DSORG=PO,DSNTYPE=LIBRARY,RECFM=FB,LRECL=80,BLKSIZE=0
//*
//********************************************************************
//* Compile the programs
//********************************************************************
//BASE64E  EXEC PROC=ASM,MEMBER=BASE64E,COND=(4,LE)
//BASE64D  EXEC PROC=ASM,MEMBER=BASE64D,COND=(4,LE)
//BASE64O  EXEC PROC=COBOL,MEMBER=BASE64O,COND=(4,LE)
//BASE64P  EXEC PROC=PLI,MEMBER=BASE64P,COND=(4,LE)
//BASE64C  EXEC PROC=C,MEMBER=BASE64C,COND=(4,LE)
//*
//********************************************************************
//* Linkedit the applications
//********************************************************************
//COBOL    EXEC PROC=LINKEDIT,COND=(4,LE)
//BINDER.SYSLIN DD *
  INCLUDE OBJLIB(BASE64O)
  INCLUDE OBJLIB(BASE64E)
  INCLUDE OBJLIB(BASE64D)
  NAME BASE64O(R)
/*
//PLI      EXEC PROC=LINKEDIT,COND=(4,LE)
//BINDER.SYSLIN DD *
  INCLUDE OBJLIB(BASE64P)
  INCLUDE OBJLIB(BASE64E)
  INCLUDE OBJLIB(BASE64D)
  NAME BASE64P(R)
/*
//C        EXEC PROC=LINKEDIT,COND=(4,LE)
//BINDER.SYSLIN DD *
  INCLUDE OBJLIB(BASE64C)
  INCLUDE OBJLIB(BASE64E)
  INCLUDE OBJLIB(BASE64D)
  NAME BASE64C(R)
/*
//*
//********************************************************************
//* Run the applications
//********************************************************************
//COBOL    EXEC PROC=RUN,MEMBER=BASE64O,COND=(4,LE)
//PLI      EXEC PROC=RUN,MEMBER=BASE64P,COND=(4,LE)
//C        EXEC PROC=RUN,MEMBER=BASE64C,COND=(4,LE)
//