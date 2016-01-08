#ifndef _BG_GENERATE_H
#define _BG_GENERATE_H

#include <stdio.h>
#include "bg_impl.h"
#include "generic_list.h"

/*This struct holds global data used by any function involved in code generation*/
typedef struct {
    unsigned int nodes;
    unsigned int edges;
    unsigned int sources;
    unsigned int sinks;
    unsigned int copies;
    unsigned int merges;
    unsigned int unaryNodes;
    unsigned int binaryNodes;
    unsigned int ternaryNodes;
    unsigned int connections;
    unsigned int toplvl_inputs;
    unsigned int toplvl_outputs;
    struct bg_list_t *visited_edges;
    struct bg_list_t *visited_nodes;
    FILE *out;
} bg_generator_vhdl_t;

/*
 * @brief Initializes a generator
 *
 * @param generator A pointer to a generator struct
 * @param fp A pointer to a FILE stream
 * @param name A name for the generated stuff
 */
bg_error bg_generator_vhdl_init(bg_generator_vhdl_t *generator, FILE *fp, const char *name);

/*
 * @brief Finalizes the dictionary and frees stuff
 *
 * @param generator A pointer to a generator struct
 */
bg_error bg_generator_vhdl_finalize(bg_generator_vhdl_t *generator);

/*
 * @brief Takes a behaviour graph and produces a stand-alone implementation in VHDL.
 *
 * The generated dictionary format depends on the template engine :)
 *
 * @param generator A pointer to a generator struct
 * @param graph A pointer to a behaviour graph
 * @param lvl Defines the current level of nesting (0 is toplvl!)
 */
bg_error bg_graph_generate_vhdl(bg_generator_vhdl_t *generator, bg_graph_t *graph, const unsigned int lvl);

#endif
