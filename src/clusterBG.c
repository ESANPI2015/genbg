#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "node_list.h"
#include "node_types/bg_node_subgraph.h"
#include "bg_transformation.h"

int main (int argc, char *argv[])
{
    int opt;
    char yamlfile[256];
    char yamlfile2[256];
    char name[256];
    unsigned int cluster = 0;
    bg_node_list_iterator_t it;
    bg_node_t *node;

    printf("Behavior Graph Agglomerative Clustering\n");

    sprintf(name, "noname");
    while ((opt = getopt(argc, argv, "hnc:")) != -1)
    {
        switch (opt)
        {
            case 'n':
                snprintf(name, 256, "%s", optarg);
                break;
            case 'h':
            default:
                fprintf(stderr, "Usage: %s [-n name] input-yaml-file number-of-clusters output-yaml-file\n", argv[0]);
                exit(EXIT_FAILURE);
                break;
        }
    }

    if ((optind >= argc) || (argc < 4))
    {
        fprintf(stderr, "Usage: %s [-n name] input-yaml-file number-of-clusters output-yaml-file\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    snprintf(yamlfile, 256, "%s", argv[optind]);
    cluster = atoi(argv[optind+1]);
    snprintf(yamlfile2, 256, "%s", argv[optind+2]);

    bg_graph_t *g = NULL;
    bg_graph_t *tg = NULL;

    bg_initialize();
    bg_graph_alloc(&g, name);
    bg_graph_from_yaml_file(yamlfile, g);
    bg_graph_split(g, &tg, cluster);
    bg_graph_to_yaml_file(yamlfile2, tg);
    printf("--- SUMMARY ---\n");
    printf("Nodes (%s): %u\n", yamlfile2, bg_node_list_size(tg->hidden_nodes));
    /*Cycle through subgraphs and save them to their files*/
    for (node = bg_node_list_first(tg->hidden_nodes, &it);
            node;
            node = bg_node_list_next(&it))
    {
        if (node->type->id == bg_NODE_TYPE_SUBGRAPH)
        {
            printf("Nodes (%s): %u\n",
                    ((subgraph_data_t *)node->_priv_data)->subgraph->name,
                    bg_node_list_size(((subgraph_data_t *)node->_priv_data)->subgraph->hidden_nodes));
            bg_graph_to_yaml_file(((subgraph_data_t *)node->_priv_data)->subgraph->name, ((subgraph_data_t *)node->_priv_data)->subgraph);
        }
    }
    bg_graph_free(g);
    bg_graph_free(tg);
    bg_terminate();

    exit(EXIT_SUCCESS);
}
