#include <stdio.h>

void floatToStdLogicVec(char *result, const float value)
{
    unsigned char *ptr = (unsigned char *)&value;
    sprintf(result, "x\"%.2x%.2x%.2x%.2x\"", ptr[3], ptr[2], ptr[1], ptr[0]);
}

