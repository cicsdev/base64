# Base64 services

Callable services to encode and decode Base64, including samples to call from COBOL, PL/I and C.

Modify the [base64.jcl](base64.jcl) file to suit your environment and then submit to compile, link and then
run all three sample applications.

## Service usage

Each module has two entry points: one to process Base64 data using an EBCDIC encoding, with another to
process Base64 data using an ASCII encoding. The following table summarises the input and output requirements:

| Entry point | Input data                                  | Output data                                 |
|-------------|---------------------------------------------|---------------------------------------------|
| BASE64E     | Binary data                                 | Base64 character data encoded using EBCDIC  |
| BASE64EA    | Binary data                                 | Base64 character data encoded using ASCII   |
| BASE64D     | Base64 character data encoded using EBCDIC  | Binary data                                 |
| BASE64DA    | Base64 character data encoded using ASCII   | Binary data                                 |

When using the encoding routines, binary data stored on z/OS should be encoded into Base64 using one of
the BASE64E routines. If the Base64 data is to be transmitted to a non-EBCDIC platform, then either:

* Encode using BASE64E and perform a codepage conversion from EBCDIC to ASCII before transmission
* Encode using BASE64EA and transmit the output without modification

When using the decoding routines, Base64 data should be decoded to binary data on z/OS using one of the
BASE64D routines. If the Base64 data has been received from a non-EBCDIC platform, then either:

* Perform a codepage conversion from ASCII to EBCDIC on the received Base64 data, then decode to binary using BASE64D
* Receive the input Base64 data without modification and decode to binary using BASE64DA

Performance is identical for the EBCDIC and ASCII variants of each service.

See the comments in the header of the [Base64 encode](base64e.asm) and [Base64 decode](base64d.asm) services for
full usage instructions.

## Examples

All examples use the same character-based input string to demonstrate basic functionality. The encoding
of text-based data is not a typical use-case of Base64: normally Base64 encoding is used to convert
binary data to printable characters suitable for transmission across channels that can only reliably
support text content.

Text input data is used in these samples as it is easily displayed and manually verified on all output devices.
The Base64-encoding of the EBCDIC character string `abcdefghijklmnopqrstuvwxyz` is:

```
gYKDhIWGh4iJkZKTlJWWl5iZoqOkpaanqKk=
```

## COBOL example usage

See [base64o.cbl](base64o.cbl) for an example of calling the encode and decode services from a COBOL
application.

## PL/I example usage

These services can be called from PL/I code, however note that
[APAR PI74835](https://www.ibm.com/support/pages/apar/PI74835) delivers the built-in functions
BASE64ENCODE and BASE64DECODE for PL/I. See the
[PL/I documentation](https://www.ibm.com/docs/en/epfz/5.3?topic=subroutines-descriptions-individual-built-in-functions-pseudovariables)
for full syntax and usage instructions.

See [base64p.pli](base64p.pli) for an example of calling the encode and decode service from a
PL/I application.

## C example usage

See [base64c.c](base64c.c) for an example of calling the encode and decode service from a standard,
non-XPLINK C application.

## Implementation

The [Base64 encode](base64e.asm) and [Base64 decode](base64d.asm) services are written in non-LE conforming
assembly. The modules use relative addressing and require an OPTABLE minimum of ZS5 to be configured in HLASM.

# License

This sample is supplied under the [Eclipse Public License 2.0](LICENSE).
