#ifndef _TEMPLATE_ENGINE
#define _TEMPLATE_ENGINE

#include <stdio.h>

#define TEMPLATE_ENGINE_MAX_STRING_LENGTH 256
#define TEMPLATE_ENGINE_DELIMITER '#'

typedef struct {
    char token[TEMPLATE_ENGINE_MAX_STRING_LENGTH];
    char repl[TEMPLATE_ENGINE_MAX_STRING_LENGTH];
} dictEntry;

/*outfile = infile*/
void copyFile(FILE *in, FILE *out);

/*outfile = infile where token <- replacement*/
void searchAndReplace(FILE *in, FILE *out, const char* token, const char* replacement);

/*outfile = infile where token <- prefix, token*/
void searchAndPrefix(FILE *in, FILE *out, const char* token, char* prefix);

/*outfile = infile where token[i] <- replacement[i]*/
void searchAndReplaceMultiple(FILE *in, FILE *out, const dictEntry *dict, const int entries);

/*Reads an entry from a dictionary*/
int readDictionary(FILE *in, dictEntry *entry);

/*Writes an entry into a dictionary*/
void writeDictionary(FILE *out, const dictEntry *entry);

#endif
