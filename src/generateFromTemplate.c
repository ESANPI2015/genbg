#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "template_engine.h"

int main (int argc, char *argv[])
{
    dictEntry *dict;
    unsigned int i;
    unsigned int replaced;
    FILE *template;
    FILE *dictionary;
    FILE *output;

    printf("Template Engine - From dictionary and template to final output\n");

    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s template-file dictionary-file output-file\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    template = fopen(argv[1], "r");
    if (!template)
    {
        perror("fopen1");
        exit(EXIT_FAILURE);
    }

    dictionary = fopen(argv[2], "r");
    if (!dictionary)
    {
        perror("fopen2");
        exit(EXIT_FAILURE);
    }

    output = fopen(argv[3], "w");
    if (!output)
    {
        perror("fopen3");
        exit(EXIT_FAILURE);
    }

    /*Populate dictionary*/
    i = 0;
    if (!(dict = malloc(sizeof(dictEntry))))
    {
        perror("malloc");
        exit(EXIT_FAILURE);
    }
    while (readDictionary(dictionary, &dict[i]))
    {
        i++;
        if (!(dict = realloc(dict, (i+1)*sizeof(dictEntry))))
        {
            perror("realloc");
            exit(EXIT_FAILURE);
        }
    }
    fclose(dictionary);

    if (i == 0)
    {
        fprintf(stderr, "Error: No entry in dictionary\n");
        exit(EXIT_FAILURE);
    }

    /*Generate output*/
    replaced = searchAndReplaceMultiple(template, output, dict, i);
    if (replaced == 0)
    {
        fprintf(stderr, "Warning: No matching tokens found in template\n");
    }
    else if (replaced < i)
    {
        fprintf(stderr, "Warning: Unmatched tokens left\n");
    }
    fclose(template);
    fclose(output);
    
    exit(EXIT_SUCCESS);
}
