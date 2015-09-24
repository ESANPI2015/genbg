#ifndef _BG_GENERATE_H
#define _BG_GENERATE_H

#include <stdio.h>
#include "bg_impl.h"
#include "generic_list.h"

/*This struct holds global data used by any function involved in code generation*/
typedef struct {
    int nodes;
    int edges;
    int code_lines;
    int toplvl_inputs;
    int toplvl_outputs;
    struct bg_list_t *visited_edges;
    FILE *out;
} bg_generator_t;

/*
 * @brief Initializes a generator
 *
 * @param generator A pointer to a generator struct
 * @param fp A pointer to a FILE stream
 * @param name A name for the generated stuff
 */
bg_error bg_generator_init(bg_generator_t *generator, FILE *fp, const char *name);

/*
 * @brief Finalizes the dictionary and frees stuff
 *
 * @param generator A pointer to a generator struct
 */
bg_error bg_generator_finalize(bg_generator_t *generator);

/*
 * @brief Takes a behaviour graph and produces a stand-alone implementation in C.
 *
 * NOTE: The generated stuff will be a dictionary with the following format:
 * token BG_GENERATE_DELIMITER replacement BG_GENERATE_DELIMITER
 *
 * @param generator A pointer to a generator struct
 * @param graph A pointer to a behaviour graph
 * @param toplvl Defines if this function is called at the toplvl of the graph
 */
bg_error bg_graph_generate(bg_generator_t *generator, bg_graph_t *graph, const int toplvl);

#endif
