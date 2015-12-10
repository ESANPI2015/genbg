#ifndef _BG_TRANSFORMATION_H
#define _BG_TRANSFORMATION_H

#include "bg_impl.h"

/*
 * @brief Splits a behaviour graph into a graph containing N subgraphs
 *
 * Increases nesting level by one
 *
 * This function uses agglomerative hierarchical clustering with complete linkage measure
 *
 * @param graph The original graph
 * @param splitted A functional equivalent graph containing N subgraphs (to keep them connected!)
 * @param num The number of subgraphs to be created
 */
bg_error bg_graph_split(const bg_graph_t *graph, bg_graph_t **splitted, const unsigned int num);

/*
 * @brief Merges all subgraphs of a behaviour graph into a common graph
 *
 * Reduces nesting level by one
 *
 * @param graph The original graph
 * @param splitted A functional equivalent graph containing no subgraphs at the top level
 */
bg_error bg_graph_merge(const bg_graph_t *graph, bg_graph_t **merged);

#endif
