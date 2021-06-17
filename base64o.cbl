      *
      *    (C) Copyright IBM Corp. 2021
      *
       identification division.
       program-id.              BASE64O.
       author.                  Ian Burnett.
       installation.            CICS Performance, IBM Hursley.
       date-written.            May 2021.

       data division.

       working-storage section.

      *    Input buffer
       01  input-data          pic x(100).

      *    Output data buffer and length
       01  output-data         pic x(100).
       01  output-length       pic 9(9) comp-5.

      *    Length after encoding
       01  encoded-length      pic 9(9) comp-5.

      *    Return code
       01  rc                  pic s9(8) binary value 0.

      *    Plaintext to use as a test case
       77  plaintext pic x(26) value 'abcdefghijklmnopqrstuvwxyz'.

       procedure division.

       main-processing section.

      *    -------------------------------------------------------------

      *    Setup data buffers
           move plaintext to input-data.
           move spaces to output-data.
           move length of output-data to output-length.

      *    Encode data in Base64
           call 'BASE64E' using
               by reference input-data
               by content length of plaintext
               by reference output-data output-length
               returning rc.

      *    Display results
           display 'Return code   : ' rc.
           display 'Output length : ' output-length.
           display 'Base64        : ' output-data.
           display ' '.

      *    Exit early if bad rc
           if rc not = 0 then go to base64-end.

      *    -------------------------------------------------------------

      *    Setup data buffers
           move spaces to input-data.
           move output-data(1:output-length) to input-data.
           move output-length to encoded-length.
           move spaces to output-data.
           move length of output-data to output-length.

      *    Decode data from Base64
           call 'BASE64D' using
               by reference input-data
               by content encoded-length
               by reference output-data output-length
               returning rc.

      *    Display results
           display 'Return code   : ' rc.
           display 'Output length : ' output-length.
           display 'Plaintext     : ' output-data.

      *    -------------------------------------------------------------

      *    All done
       base64-end.
           move rc to return-code.
           goback.

