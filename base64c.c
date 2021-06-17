
/*
 * (C) Copyright IBM Corp. 2021
 */

#include <stdio.h>
#include <string.h>

#pragma linkage(base64Encode, OS)
#pragma map(base64Encode, "BASE64E")

#pragma linkage(base64Decode, OS)
#pragma map(base64Decode, "BASE64D")

/* External Base64 encoding routine */
int base64Encode(void *, unsigned int, char *, unsigned int *);

/* External Base64 decoding routine */
int base64Decode(char *, unsigned int, void *, unsigned int *);

/* Plaintext to use as a test case */
const unsigned char * plaintext = "abcdefghijklmnopqrstuvwxyz";



int main(char ** argv, int argc)
{
    /* Input buffer */
    unsigned char inputData[100];

    /* Output data buffer and length */
    unsigned char outputData[100];
    unsigned int outputLength;

    /* Length after encoding */
    unsigned int encodedLength;

    /* Return code */
    int rc = 0;


    /* Setup data buffers */
    /* Allow for null-terminator in outputLength */
    memset(inputData, '\0', sizeof(inputData));
    strncpy(inputData, plaintext, sizeof(inputData));
    memset(outputData, '\0', sizeof(outputData));
    outputLength = sizeof(outputData) - 1;

    /* Encode data in Base64 */
    rc = base64Encode(inputData, strlen(inputData),
                      outputData, &outputLength);

    /* Routine does not null-terminate strings */
    outputData[outputLength] = '\0';

    /* Display results */
    printf("Return code   : %d\n", rc);
    printf("Output length : %d\n", outputLength);
    printf("Base64        : %s\n", outputData);
    printf(" \n");

    /* Exit early if bad rc */
    if ( rc != 0 ) {
        return rc;
    }

    /* ------------------------------------- */

    /* Setup data buffers */
    /* Allow for null-terminator in output length */
    memset(inputData, '\0', sizeof(inputData));
    strncpy(inputData, outputData, sizeof(inputData));
    encodedLength = outputLength;
    memset(outputData, '\0', sizeof(outputData));
    outputLength = sizeof(outputData) - 1;

    /* Decode data from Base64 */
    rc = base64Decode(inputData, encodedLength,
                      outputData, &outputLength);

    /* Routine does not null-terminate strings */
    outputData[outputLength] = '\0';

    /* Display results */
    printf("Return code   : %d\n", rc);
    printf("Output length : %d\n", outputLength);
    printf("Plaintext     : %s\n", outputData);


    /* All done */
    return rc;
}

