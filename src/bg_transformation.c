#include "bg_transformation.h"
#include "bg_graph.h"
#include "bg_node.h"
#include "generic_list.h"
#include "node_list.h"
#include "edge_list.h"
#include "node_types/bg_node_subgraph.h"
#include <stdio.h>
#include <string.h>

/*MOVE TO BG_GRAPH.C*/
bg_error bg_graph_disconnect_node(bg_graph_t *graph, bg_node_id_t node_id)
{
    bg_error err = bg_SUCCESS;
    bg_node_t *node;
    bg_edge_t *edge;
    bg_edge_list_t *edge_list;
    bg_edge_list_iterator_t it;
    int i, j;

    bg_edge_list_init(&edge_list);

    /*Find node*/
    if ((err = bg_graph_find_node(graph, node_id, &node)) != bg_SUCCESS)
        return err;

    /*Register edges to be removed*/
    for (i = 0; i < node->input_port_cnt; ++i)
        for (j = 0; j < node->input_ports[i]->num_edges; ++j)
            bg_edge_list_append(edge_list, node->input_ports[i]->edges[j]);
    for (i = 0; i < node->output_port_cnt; ++i)
        for (j = 0; j < node->output_ports[i]->num_edges; ++j)
            bg_edge_list_append(edge_list, node->output_ports[i]->edges[j]);

    /*Remove registered edges*/
    for (edge = bg_edge_list_first(edge_list, &it);
            edge;
            edge = bg_edge_list_next(&it))
        bg_graph_remove_edge(graph, edge->id);

    bg_edge_list_deinit(edge_list);
    return err;
}

unsigned int bg_node_list_connectivity(const bg_node_list_t *listA, const bg_node_list_t *listB)
{
    bg_node_t *nodeA, *nodeB;
    bg_node_list_iterator_t itA, itB;
    unsigned int connectivity = 0;
    int i,j;

    /*For each node in lists: find conectivity between lists*/
    for (nodeA = bg_node_list_first(listA, &itA);
        nodeA;
        nodeA = bg_node_list_next(&itA))
    {
        /*For each incoming edge: find src in listB*/
        for (i = 0; i < nodeA->input_port_cnt; ++i)
            for (j = 0; j < nodeA->input_ports[i]->num_edges; ++j)
                if (bg_node_list_find(listB, nodeA->input_ports[i]->edges[j]->source_node, &itB))
                    connectivity++;
        /*For each outgoing edge: find dest in listB*/
        for (i = 0; i < nodeA->output_port_cnt; ++i)
            for (j = 0; j < nodeA->output_ports[i]->num_edges; ++j)
                if (bg_node_list_find(listB, nodeA->output_ports[i]->edges[j]->sink_node, &itB))
                    connectivity++;
    }
    
    return connectivity;
}

/*MOVE TO GENERIC_LIST.C*/
void bg_node_list_merge(bg_node_list_t *dest, bg_node_list_t *src)
{
    bg_node_t *node;
    bg_node_list_iterator_t it_src, it_dest;

    /*Append every node of list src to list dest*/
    for (node = bg_node_list_first(src, &it_src);
        node;
        node = bg_node_list_next(&it_src))
    {
        bg_node_list_append(dest, node);
    }
    /*Clear list src*/
    bg_node_list_clear(src);
}

bg_error bg_node_get_idx(bg_node_t *node, unsigned int *idx)
{
    bg_error err = bg_SUCCESS;
    bg_graph_t *parent = node->_parent_graph;

    switch (node->type->id)
    {
        case bg_NODE_TYPE_INPUT:
            for (*idx = 0; *idx < parent->input_port_cnt; ++(*idx))
                if (parent->input_ports[*idx] == node->input_ports[0])
                    break; /*NOTE: Breaks the loop only!*/
            if (*idx >= parent->input_port_cnt)
                return bg_ERR_NODE_NOT_FOUND;
            break;
        case bg_NODE_TYPE_OUTPUT:
            for (*idx = 0; *idx < parent->output_port_cnt; ++(*idx))
                if (parent->output_ports[*idx] == node->output_ports[0])
                    break;
            if (*idx >= parent->output_port_cnt)
                return bg_ERR_NODE_NOT_FOUND;
            break;
        default:
            return bg_ERR_WRONG_TYPE;
    }
    return err;
}

/*MOVE TO BG_GRAPH.C*/
bg_error bg_graph_clone_node(bg_graph_t *graph, bg_node_t *node)
{
    bg_error err = bg_SUCCESS;
    bg_graph_t *srcsubgraph = NULL;
    bg_graph_t *subgraph = NULL;
    int i;

    /*For some nodes we have to do additional stuff*/
    switch (node->type->id)
    {
        case bg_NODE_TYPE_INPUT:
            if ((err = bg_graph_create_input(graph, node->name, node->id)) != bg_SUCCESS)
                return err;
            break;
        case bg_NODE_TYPE_OUTPUT:
            if ((err = bg_graph_create_output(graph, node->name, node->id)) != bg_SUCCESS)
                return err;
            break;
        case bg_NODE_TYPE_EXTERN:
            if ((err = bg_graph_create_node(graph, node->name, node->id, node->type->id)) != bg_SUCCESS)
                return err;
            if ((err = bg_node_set_extern(graph, node->id, node->type->name)) != bg_SUCCESS)
                return err;
            break;
        case bg_NODE_TYPE_SUBGRAPH:
            srcsubgraph = ((subgraph_data_t *)node->_priv_data)->subgraph;
            if ((err = bg_graph_create_node(graph, node->name, node->id, node->type->id)) != bg_SUCCESS)
                return err;
            /*Clone the embedded subgraph*/
            if ((err = bg_graph_alloc(&subgraph, srcsubgraph->name)) != bg_SUCCESS)
                return err;
            if ((err = bg_graph_clone(subgraph, srcsubgraph)) != bg_SUCCESS)
            {
                /*Destroy subgraph*/
                bg_graph_free(subgraph);
                return err;
            }
            if ((err = bg_node_set_subgraph(graph, node->id, subgraph)) != bg_SUCCESS)
            {
                /*Destroy subgraph*/
                bg_graph_free(subgraph);
                return err;
            }
            break;
        default:
            if ((err = bg_graph_create_node(graph, node->name, node->id, node->type->id)) != bg_SUCCESS)
                return err;
            break;
    }

    /*For all nodes: set input name(s), merge(s) and output name(s)*/
    for (i = 0; i < node->input_port_cnt; ++i)
        if ((err = bg_node_set_input(graph, node->id, i,
                        node->input_ports[i]->merge->id,
                        node->input_ports[i]->defaultValue,
                        node->input_ports[i]->bias,
                        node->input_ports[i]->name)) != bg_SUCCESS)
        {
            if (subgraph)
                bg_graph_free(subgraph);
            return err;
        }
    for (i = 0; i < node->output_port_cnt; ++i)
        if ((err = bg_node_set_output(graph, node->id, i,
                        node->output_ports[i]->name)) != bg_SUCCESS)
        {
            if (subgraph)
                bg_graph_free(subgraph);
            return err;
        }

    return err;
}

bg_error bg_graph_create(bg_graph_t **graph, const char *name, bg_node_list_t *node_list, bg_edge_list_t *edge_list)
{
    bg_error err = bg_SUCCESS;
    bg_graph_t *new_graph;
    bg_node_t *node;
    bg_node_list_iterator_t it;
    bg_edge_t *edge;
    bg_edge_list_iterator_t it2;
    unsigned int edgeId = 1;
    unsigned int nodeId = 0;
    unsigned int srcId, srcIdx, sinkId, sinkIdx;
    bg_real weight = 1.0;
    bool foundSrc, foundSink, foundPort;
    unsigned int i;

    /*Create new graph*/
    if ((err = bg_graph_alloc(&new_graph, name)) != bg_SUCCESS)
        return err;

    /*For each node: clone it to the graph*/
    for (node = bg_node_list_first(node_list, &it);
            node;
            node = bg_node_list_next(&it))
    {
        if ((err = bg_graph_clone_node(new_graph, node)) != bg_SUCCESS)
        {
            bg_graph_free(new_graph);
            return err;
        }
        if (node->id > nodeId)
            nodeId = node->id;
    }
    nodeId++;

    /*For each edge: Check if source and sink nodes are in list and create edge*/
    for (edge = bg_edge_list_first(edge_list, &it2);
            edge;
            edge = bg_edge_list_next(&it2))
    {
        foundSrc = bg_node_list_find(node_list, edge->source_node, &it);
        foundSink = bg_node_list_find(node_list, edge->sink_node, &it);
        foundPort = false;
        if (foundSrc && foundSink)
        {
            /*Create internal edge*/
            srcId = edge->source_node->id;
            srcIdx = edge->source_port_idx;
            sinkId = edge->sink_node->id;
            sinkIdx = edge->sink_port_idx;
            weight = edge->weight;
        }
        else if (foundSink)
        {
            /*Search for an INPUT node at the corresponding input port of the sink node*/
            bg_graph_find_node(new_graph, edge->sink_node->id, &node);
            for (i = 0; i < node->input_ports[edge->sink_port_idx]->num_edges; ++i)
                if (node->input_ports[edge->sink_port_idx]->edges[i]->source_node->type->id == bg_NODE_TYPE_INPUT)
                    foundPort = true;
            /*Create Input for an entering edge iff NONE exists yet*/
            if (!foundPort)
            {
                if ((err = bg_graph_create_input(new_graph, node->name, nodeId)) != bg_SUCCESS)
                {
                    bg_graph_free(new_graph);
                    return err;
                }
                /*Inherit the merge type and values from associated node*/
                bg_node_set_merge(new_graph,
                        nodeId,
                        0,
                        node->input_ports[edge->sink_port_idx]->merge->id,
                        node->input_ports[edge->sink_port_idx]->defaultValue,
                        node->input_ports[edge->sink_port_idx]->bias);
                /*And wire it so Src*/
                srcId = nodeId;
                srcIdx = 0;
                sinkId = edge->sink_node->id;
                sinkIdx = edge->sink_port_idx;
                weight = 1.0;
                nodeId++;
            }
        }
        else if (foundSrc)
        {
            /*Search for an OUTPUT node at the corresponding output port of the source node*/
            bg_graph_find_node(new_graph, edge->source_node->id, &node);
            for (i = 0; i < node->output_ports[edge->source_port_idx]->num_edges; ++i)
                if (node->output_ports[edge->source_port_idx]->edges[i]->sink_node->type->id == bg_NODE_TYPE_OUTPUT)
                    foundPort = true;
            /*Create Output for a leaving edge iff NONE exists yet*/
            if (!foundPort)
            {
                if ((err = bg_graph_create_output(new_graph, node->name, nodeId)) != bg_SUCCESS)
                {
                    bg_graph_free(new_graph);
                    return err;
                }
                /*And wire it to sink*/
                srcId = edge->source_node->id;
                srcIdx = edge->source_port_idx;
                sinkId = nodeId;
                sinkIdx = 0;
                weight = 1.0;
                nodeId++;
            }
        } else
            continue;

        /*Suppress edge creation iff a INPUT or OUTPUT node has been found*/
        if (foundPort)
            continue;

        /*Create edge*/
        if ((err = bg_graph_create_edge(new_graph,
                            srcId,
                            srcIdx,
                            sinkId,
                            sinkIdx,
                            weight,
                            edgeId)) != bg_SUCCESS)
        {
            bg_graph_free(new_graph);
            return err;
        }
        edgeId++;
    }

    *graph = new_graph;
    return err;
}


bg_error bg_graph_split(const bg_graph_t *graph, bg_graph_t **splitted, const unsigned int num)
{
    bg_error err = bg_SUCCESS;
    bg_graph_t *new_graph;
    bg_graph_t *new_subgraph[num];
    unsigned int subgraphId[num];
    unsigned int nodes;
    unsigned int maxId = 0;
    char subname[256];

    bg_node_t *current;
    bg_node_list_iterator_t it;

    bg_edge_t *edge;
    bg_edge_list_iterator_t it2;
    unsigned int srcId, srcIdx, sinkId, sinkIdx;

    bg_node_list_t **lists;
    unsigned int sizeI, sizeJ, connectivity;
    unsigned int maxI, maxJ, maxConnectivity, minSize;

    int i,j,k;
    bool srcInGraph, sinkInGraph;

    nodes = bg_node_list_size(graph->hidden_nodes);
    /*We need at least num nodes*/
    if (nodes < num)
        return bg_ERR_WRONG_ARG_COUNT;
    /*If number of nodes == clusters, we are done*/
    if (nodes == num)
        return err;
    /*Create empty graph*/
    err = bg_graph_alloc(&new_graph, graph->name);
    if (err != bg_SUCCESS)
        return err;
    /* clone load path */
     if(graph->load_path) {
         char *name_copy = malloc(strlen(graph->load_path)+1);
         strcpy(name_copy, graph->load_path);
         new_graph->load_path = name_copy;
     }

    /*Find maximum Id in input nodes and clone them*/
    for (current = bg_node_list_first(graph->input_nodes, &it);
        current;
        current = bg_node_list_next(&it))
    {
        if (current->id > maxId)
            maxId = current->id;
        bg_graph_clone_node(new_graph, current);
    }
    /*Find maximum Id in output nodes and clone them*/
    for (current = bg_node_list_first(graph->output_nodes, &it);
        current;
        current = bg_node_list_next(&it))
    {
        if (current->id > maxId)
            maxId = current->id;
        bg_graph_clone_node(new_graph, current);
    }
    /*Create array of list ptr*/
    lists = (bg_node_list_t **)calloc(nodes, sizeof(bg_node_list_t *));
    /*Assign each original node to a list and update maximum Id*/
    i = 0;
    for (current = bg_node_list_first(graph->hidden_nodes, &it);
        current;
        current = bg_node_list_next(&it))
    {
        if (current->id > maxId)
            maxId = current->id;
        bg_node_list_init(&lists[i]);
        bg_node_list_append(lists[i], current);
        i++;
    }
    maxId++;
    /*Now we have new_graph with all nodes but no edges :)*/

    /*III. Agglomerative clustering:
     * The idea is to minimize inter-subgraph connectivity and to maximize intra-subgraph connectivity*/
    /*Repeat until the number of NON-EMPTY lists is equal to desired number of subgraphs*/
    for (k = nodes; k > num; --k)
    {
        /*Setting to zero means that there will always be a merge (even if there are only unconnected nodes!); setting to one would prevent this!*/
        maxConnectivity = 0;
        minSize = -1; 
        /*Cycle through pairs of lists*/
        for (i = 0; i < nodes; ++i)
        {
            /*Skip empty lists*/
            if ((sizeI = bg_node_list_size(lists[i])) <= 0)
                continue;

            /*Connectivity symmetry: C(i,j) = C(j,i)*/
            for (j = i+1; j < nodes; ++j)
            {
                /*Skip empty lists*/
                if ((sizeJ = bg_node_list_size(lists[j])) <= 0)
                    continue;

                /*Calculate complete linkage count*/
                connectivity = bg_node_list_connectivity(lists[i], lists[j]);

                /*NOTE: This is very sensitive:
                 * > produces only one large cluster
                 * To get balanced results, we use the sizes of the clusters to be merged as a tie breaker*/
                if ((connectivity > maxConnectivity) || ((connectivity == maxConnectivity) && (sizeI + sizeJ < minSize)))
                {
                    maxI = i;
                    maxJ = j;
                    maxConnectivity = connectivity;
                    minSize = sizeI + sizeJ;
                }
            }
        }
        /*fprintf(stderr, "Step: %u -> max. Connectivity: %u ListA: %u ListB: %u Size: %u\n", nodes-k, maxConnectivity, maxI, maxJ, minSize);*/
        /*Merge the lists with maxConnectivity, second list will be empty afterwards*/
        bg_node_list_merge(lists[maxI], lists[maxJ]);
        /*Each merge decreases the number of non-empty lists by one*/
    }

    j = 0;
    for (i = 0; i < nodes; ++i)
    {
        /*Skip empty lists*/
        if ((minSize = bg_node_list_size(lists[i])) <= 0)
            continue;
        /*fprintf(stderr, "Subgraph: %u List: %u Size: %u\n", j, i, minSize);*/

        /*Create a new subgraph from the found clusters and the original edge list*/
        snprintf(subname, 256, "%s_subg%u.yml", graph->name, maxId);
        err = bg_graph_create(&new_subgraph[j], subname, lists[i], graph->edge_list); // At second subgraph: ERROR IN HERE
        
        /*Create a node for the subgraph in the parent graph*/
        snprintf(subname, 256, "%s_subg%u", graph->name, maxId);
        err = bg_graph_create_node(new_graph, subname, maxId, bg_NODE_TYPE_SUBGRAPH);
        subgraphId[j] = maxId;

        /*Assign the subgraphs to the subgraph nodes*/
        err = bg_node_set_subgraph(new_graph, maxId, new_subgraph[j]);

        j++;
        maxId++;
    }
    /*fprintf(stderr, "Created %u subgraphs\n", j);*/

    /*For each edge in original edge list: create edges to wire subgraphs and inputs/outputs together*/
    for (edge = bg_edge_list_first(graph->edge_list, &it2);
            edge;
            edge = bg_edge_list_next(&it2))
    {
        srcInGraph = false;
        sinkInGraph = false;
        /*Find source node in a) new_graph inputs or b) a subgraph*/
        if (bg_node_list_find(graph->input_nodes, edge->source_node, &it))
        {
            srcInGraph = true;
            srcId = edge->source_node->id;
            srcIdx = 0;
        } else {
            for (i = 0; i < num; ++i)
            {
                bg_graph_find_node(new_subgraph[i], edge->source_node->id, &current);
                /*Because subgraph ids do not have to be unique globally we also check type*/
                if ((current != NULL) && (current->type->id == edge->source_node->type->id))
                    break;
            }
            srcId = subgraphId[i];
            /*Find THE associated OUTPUT node!*/
            for (k = 0; k < current->output_ports[edge->source_port_idx]->num_edges; ++k)
                if (current->output_ports[edge->source_port_idx]->edges[k]->sink_node->type->id == bg_NODE_TYPE_OUTPUT)
                {
                    bg_node_get_idx(current->output_ports[edge->source_port_idx]->edges[k]->sink_node, &srcIdx);
                    break;
                }
        }
        /*Find sink node in a) new_graph outputs or b) a subgraph*/
        if (bg_node_list_find(graph->output_nodes, edge->sink_node, &it))
        {
            sinkInGraph = true;
            sinkId = edge->sink_node->id;
            sinkIdx = 0;
        } else {
            for (j = 0; j < num; ++j)
            {
                bg_graph_find_node(new_subgraph[j], edge->sink_node->id, &current);
                /*Because subgraph ids do not have to be unique globally we also check type*/
                if ((current != NULL) && (current->type->id == edge->sink_node->type->id))
                    break;
            }
            sinkId = subgraphId[j];
            /*Find THE associated INPUT node!*/
            for (k = 0; k < current->input_ports[edge->sink_port_idx]->num_edges; ++k)
                if (current->input_ports[edge->sink_port_idx]->edges[k]->source_node->type->id == bg_NODE_TYPE_INPUT)
                {
                    bg_node_get_idx(current->input_ports[edge->sink_port_idx]->edges[k]->source_node, &sinkIdx);
                    break;
                }
        }
        /*If both are in the SAME subgraph do nothing*/
        if (!srcInGraph && !sinkInGraph && (i == j)) {
            continue;
        }

        /*Otherwise, create an edge (nearly a clone)*/
        err = bg_graph_create_edge(new_graph,
                            srcId,
                            srcIdx,
                            sinkId,
                            sinkIdx,
                            edge->weight,
                            edge->id);
    }

    /*Cleanup*/
    /*fprintf(stderr, "Cleanup\n");*/
    for (i = 0; i < nodes; ++i)
        /*Due to unsafe deinit/clear we have to cleanup lists ourself :(*/
        if (bg_node_list_size(lists[i]) > 0)
            bg_list_deinit(lists[i]);
        else
            free(lists[i]);
    free(lists);

    /*Return the created graph*/
    *splitted = new_graph;
    return err;
}

bg_error bg_graph_merge(const bg_graph_t *graph, bg_graph_t **merged)
{
    return bg_ERR_NOT_IMPLEMENTED;
}
