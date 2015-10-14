#include "template_engine.h"
#include <string.h>

enum FSM {
    FSM_SEARCH,
    FSM_COMPARE
};

void copyFile(FILE *in, FILE *out)
{
    int c;

    while ((c = fgetc(in)) != EOF)
        fputc(c, out);
}

unsigned int readDictionary(FILE *in, dictEntry *entry)
{
    int ret;
    char fmt[TEMPLATE_ENGINE_MAX_STRING_LENGTH];
    sprintf(fmt, "%%[^%c]%c", TEMPLATE_ENGINE_DELIMITER, TEMPLATE_ENGINE_DELIMITER);
    ret = fscanf(in, fmt, &entry->token);
    if (ret < 1)
        return 0;
    ret = fscanf(in, fmt, &entry->repl);
    if (ret < 1)
        return 0;
    return 1;
}

void writeDictionary(FILE *out, const dictEntry *entry)
{
    fprintf(out, "%s%c%s%c",entry->token, TEMPLATE_ENGINE_DELIMITER, entry->repl, TEMPLATE_ENGINE_DELIMITER);
}

unsigned int searchAndPrefix(FILE *in, FILE *out, const char* token, char* prefix)
{
    /*add the token to the replacement*/
    strncat(prefix, token, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    /*Call SaR*/
    return searchAndReplace(in, out, token, prefix);
}


unsigned int searchAndReplaceMultiple(FILE *in, FILE *out, const dictEntry *dict, const int entries)
{
    FILE *tmp1;
    FILE *tmp2;
    unsigned int i = 0;
    unsigned int replaced = 0;

    if (!dict)
        return replaced;

    /*Create temporary files*/
    tmp1 = tmpfile();

    /*Copy input file*/
    copyFile(in, tmp1);
    rewind(tmp1);

    /*Cycle through dictionary*/
    /*NOTE: This is tricky stuff!!!!*/
    for (i = 0; i < entries; ++i)
    {
        /*Open and truncate output file*/
        tmp2 = tmpfile();
        /*Call SaR*/
        if (searchAndReplace(tmp1, tmp2, dict[i].token, dict[i].repl))
            replaced++;
        /*Rewind result and close tmp1*/
        fclose(tmp1);
        rewind(tmp2);
        /*Copy tmp2 to tmp1 with tmp1 being truncated by reopening*/
        tmp1 = tmpfile();
        copyFile(tmp2, tmp1);
        /*Rewind result and close tmp2*/
        rewind(tmp1);
        fclose(tmp2);
    }

    /*Copy to output file*/
    rewind(tmp1);
    copyFile(tmp1, out);

    /*Close temporary files*/
    fclose(tmp1);
    return replaced;
}

unsigned int searchAndReplace(FILE *in, FILE *out, const char* token, const char* replacement)
{
    enum FSM state = FSM_SEARCH;
    int c,idx;
    long pos;
    unsigned int replaced = 0;

    if (!token || !replacement)
        return replaced;

    while ((c = fgetc(in)) != EOF)
    {
        switch (state)
        {
            case FSM_SEARCH:
                /*Search until first matching character found*/
                if (token[0] == (char)c)
                {
                    /*MATCH !*/
                    idx = 1;
                    pos = ftell(in);
                    state = FSM_COMPARE;
                } else {
                    /*... no match, copy*/
                    fputc(c, out);
                }
                break;
            case FSM_COMPARE:
                if (!token[idx])
                {
                    /*MATCH !*/
                    idx = 0;
                    while(replacement[idx])
                    {
                        fputc(replacement[idx], out);
                        idx++;
                    }
                    fputc(c, out);
                    replaced++;
                    state = FSM_SEARCH;
                }
                else if (token[idx] != (char)c)
                {
                    /*NO MATCH !*/
                    fseek(in, pos, SEEK_SET);
                    fputc(token[0], out);
                    state = FSM_SEARCH;
                }
                else
                    idx++;
                break;
        }
    }

    return replaced;
}
