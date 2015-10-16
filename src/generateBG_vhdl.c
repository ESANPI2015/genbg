#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "bg_generate_vhdl.h"

int main (int argc, char *argv[])
{
    int opt;
    FILE *out;
    char yamlfile[256];
    char name[256];

    printf("Behavior Graph to Dictionary Generator - VHDL language\n");

    sprintf(name, "noname");
    while ((opt = getopt(argc, argv, "hn:")) != -1)
    {
        switch (opt)
        {
            case 'n':
                snprintf(name, 256, "%s", optarg);
                break;
            case 'h':
            default:
                fprintf(stderr, "Usage: %s [-n name] yaml-file dictionary-file\n", argv[0]);
                exit(EXIT_FAILURE);
                break;
        }
    }

    if ((optind >= argc) || (argc < 3))
    {
        fprintf(stderr, "Usage: %s [-n name] yaml-file dictionary-file\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    snprintf(yamlfile, 256, "%s", argv[optind]);
    out = fopen(argv[optind+1], "w");
    if (!out)
    {
        perror("fopen");
        exit(EXIT_FAILURE);
    }
    
    bg_graph_t *g = NULL;
    bg_generator_t gen;

    bg_initialize();
    bg_graph_alloc(&g, name);
    bg_graph_from_yaml_file(yamlfile, g);
    bg_generator_init(&gen, out, name);
    switch (bg_graph_generate(&gen, g, 0))
    {
        case bg_ERR_WRONG_TYPE:
            fprintf(stderr, "Error: Wrong type at node %u\n", gen.nodes);
            exit(EXIT_FAILURE);
        case bg_ERR_NOT_IMPLEMENTED:
            fprintf(stderr, "Error: Merge or node function at node %u not implemented\n", gen.nodes);
            exit(EXIT_FAILURE);
        default:
            break;
    }
    bg_generator_finalize(&gen);
    bg_graph_free(g);
    bg_terminate();

    fclose(out);

    exit(EXIT_SUCCESS);
}
