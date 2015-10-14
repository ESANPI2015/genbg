#ifndef _BG_GENERATE_H
#define _BG_GENERATE_H

#include <stdio.h>
#include "bg_impl.h"
#include "generic_list.h"

/*This struct holds global data used by any function involved in code generation*/
typedef struct {
    unsigned int nodes;
    unsigned int edges;
    unsigned int code_lines;
    unsigned int toplvl_inputs;
    unsigned int toplvl_outputs;
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
 * The generated dictionary format depends on the template engine :)
 *
 * @param generator A pointer to a generator struct
 * @param graph A pointer to a behaviour graph
 * @param lvl Defines the current level of nesting (0 is toplvl!)
 */
bg_error bg_graph_generate(bg_generator_t *generator, bg_graph_t *graph, const unsigned int lvl);

#endif
