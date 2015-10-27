#include "bagel.h"
#include "bg_generate_vhdl.h"
#include "node_types/bg_node_subgraph.h"
#include "node_list.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "template_engine.h"

static void floatToStdLogicVec(char *result, const float value)
{
    unsigned char *ptr = (unsigned char *)&value;
    sprintf(result, "x\"%.2x%.2x%.2x%.2x\"", ptr[3], ptr[2], ptr[1], ptr[0]);
}

/*This function generates dictionary entries for a connection between an output of a component and an input of an component*/
static void addConnection(bg_generator_t *g, const char* from, const unsigned int fidx, const int foutput, const char *to, const unsigned int tidx, const int tinput)
{
    dictEntry entry;
    char temp[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    /*I. Connect the data ports*/
    sprintf(entry.token, "@connection%u@", g->connections);
    if (tinput < 0)
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s(%u) <= ", to, tidx);
    else
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s(%u)(%u) <= ", to, tidx, (unsigned int)tinput);
    if (foutput < 0)
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s(%u);\n", from, fidx);
    else
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s(%u)(%u);\n", from, fidx, (unsigned int)foutput);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    /*II. Connect the request signals*/
    if (tinput < 0)
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s_req(%u) <= ", to, tidx);
    else
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s_req(%u)(%u) <= ", to, tidx, (unsigned int)tinput);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    if (foutput < 0)
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s_req(%u);\n", from, fidx);
    else
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s_req(%u)(%u);\n", from, fidx, (unsigned int)foutput);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    /*III. Connect the ack signals*/
    if (foutput < 0)
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s_ack(%u) <= ", from, fidx);
    else
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "from_%s_ack(%u)(%u) <=", from, fidx, (unsigned int)foutput);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    if (tinput < 0)
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s_ack(%u);\n", to, tidx);
    else
        snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "to_%s_ack(%u)(%u);\n", to, tidx, (unsigned int)tinput);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    snprintf(temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "\n@connection%u@", g->connections+1);
    strncat(entry.repl, temp, TEMPLATE_ENGINE_MAX_STRING_LENGTH);
    writeDictionary(g->out, &entry);
    g->connections++;
}

static unsigned int addEdge(bg_generator_t *g, const float weight, const int isBackedge)
{
    dictEntry entry;
    char temp[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    sprintf(entry.token, "@weight%u@", g->edges);
    floatToStdLogicVec(temp, weight);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => %s, -- %ff\n@weight%u@", g->edges, temp, weight, g->edges+1);
    writeDictionary(g->out, &entry);
    sprintf(entry.token, "@backEdge%u@", g->edges);
    if (isBackedge)
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => true,\n@backEdge%u@", g->edges, g->edges+1);
    else
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "@backEdge%u@", g->edges+1);
    writeDictionary(g->out, &entry);
    return g->edges++;
}

static unsigned int addSource(bg_generator_t *g, const float value)
{
    dictEntry entry;
    char temp[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    sprintf(entry.token, "@srcValue%u@", g->sources);
    floatToStdLogicVec(temp, value);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => %s, -- %ff\n@srcValue%u@", g->sources, temp, value, g->sources+1);
    writeDictionary(g->out, &entry);
    return g->sources++;
}

static unsigned int addSink(bg_generator_t *g)
{
    return g->sinks++;
}

static int addMerge(bg_generator_t *g, const bg_merge_type type, const unsigned int inputs, const float bias, const float defValue)
{
    int id = -1;
    dictEntry entry;
    char temp[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    if (inputs < 1)
    {
        /*SPECIAL RULE: An unconnected merge will become a source with a default value*/
        switch (type)
        {
            case bg_MERGE_TYPE_SUM:
                id = addSource(g, defValue + bias);
                break;
            case bg_MERGE_TYPE_PRODUCT:
                id = addSource(g, defValue * bias);
                break;
            case bg_MERGE_TYPE_MAX:
            case bg_MERGE_TYPE_MIN:
            case bg_MERGE_TYPE_WEIGHTED_SUM:
            case bg_MERGE_TYPE_MEAN:
            case bg_MERGE_TYPE_NORM:
            case bg_MERGE_TYPE_MEDIAN:
            default:
                break;
        }
        return id;
    }

    sprintf(entry.token, "@mergeType%u@", g->merges);
    switch (type)
    {
        case bg_MERGE_TYPE_SUM:
            snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => sum,\n@mergeType%u@", g->merges, g->merges+1);
            break;
        case bg_MERGE_TYPE_PRODUCT:
            snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => prod,\n@mergeType%u@", g->merges, g->merges+1);
            break;
        case bg_MERGE_TYPE_MAX:
        case bg_MERGE_TYPE_MIN:
        case bg_MERGE_TYPE_WEIGHTED_SUM:
        case bg_MERGE_TYPE_MEAN:
        case bg_MERGE_TYPE_NORM:
        case bg_MERGE_TYPE_MEDIAN:
        default:
            return id;
    }
    writeDictionary(g->out, &entry);
    sprintf(entry.token, "@mergeBias%u@", g->merges);
    floatToStdLogicVec(temp, bias);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => %s, -- %ff\n@mergeBias%u@", g->merges, temp, bias, g->merges+1);
    writeDictionary(g->out, &entry);
    sprintf(entry.token, "@mergeInputs%u@", g->merges);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => %u,\n@mergeInputs%u@", g->merges, inputs, g->merges+1);
    writeDictionary(g->out, &entry);

    return g->merges++;
}

static unsigned int addCopy(bg_generator_t *g, const unsigned int outputs)
{
    dictEntry entry;
    char temp[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    if (outputs < 1)
    {
        /*SPECIAL RULE: An unconnected copy will become a sink*/
        return addSink(g);
    }

    sprintf(entry.token, "@copyOutputs%u@", g->copies);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => %u,\n@copyOutputs%u@", g->copies, outputs, g->copies+1);
    writeDictionary(g->out, &entry);
    return g->copies++;
}

bg_error bg_node_generate(bg_generator_t *g, bg_node_t *n, const unsigned int lvl)
{
    dictEntry entry;
    bg_error err = bg_SUCCESS;
    bg_list_iterator_t it, it2;
    int i,j;
    unsigned int edgeId;
    int mergeId[n->input_port_cnt];
    unsigned int copyId[n->output_port_cnt];
    int suppress = 0;
    unsigned int backedge;
    unsigned int nodeId;
    char nodeType[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    /*At first we have to generate merges for each node input*/
    /*SPECIAL RULE 1: Suppress merge generation at toplvl INPUT nodes*/
    if ((lvl == 0) && (n->type->id == bg_NODE_TYPE_INPUT))
        suppress = 1;
    /*SPECIAL RULE 2: Suppress merge generation at SUBGRAPH inputs*/
    if (n->type->id == bg_NODE_TYPE_SUBGRAPH)
        suppress = 1;
    for (i = 0; (i < n->input_port_cnt) && !suppress; ++i)
    {
        // I. generate merge or source (if num_edges == 0)
        mergeId[i] = addMerge(g, n->input_ports[i]->merge->id, n->input_ports[i]->num_edges, n->input_ports[i]->bias, n->input_ports[i]->defaultValue);
        if (mergeId[i] < 0)
            return bg_ERR_NOT_IMPLEMENTED;

        for (j = 0; j < n->input_ports[i]->num_edges; ++j)
        {
            // II. Register and generate edges, find back edges
            /*Check if edge has already been visited*/
            if (!bg_list_find(g->visited_edges, n->input_ports[i]->edges[j], &it))
            {
                /*Iff the source node of an edge has not been visited yet, we have found a backedge!*/
                backedge = bg_list_find(g->visited_nodes, n->input_ports[i]->edges[j]->source_node, &it2) ? 0 : 1;
                /*Register edge, assign new id in increasing order*/
                edgeId = addEdge(g, n->input_ports[i]->edges[j]->weight, backedge);
                n->input_ports[i]->edges[j]->id = edgeId;
                bg_list_append(g->visited_edges, n->input_ports[i]->edges[j]);
            } else {
                edgeId = n->input_ports[i]->edges[j]->id;
            }
            // III. connect edges to merge
            addConnection(g, "edge", edgeId, -1, "merge", mergeId[i], j);
        }
    }

    /* Generate node*/
    switch (n->type->id)
    {
        case bg_NODE_TYPE_INPUT:
        case bg_NODE_TYPE_OUTPUT:
        case bg_NODE_TYPE_PIPE:
            sprintf(entry.token, "@unaryType%u@", g->unaryNodes);
            snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%u => pipe,\n@unaryType%u@", g->unaryNodes, g->unaryNodes+1);
            writeDictionary(g->out, &entry);
            nodeId = g->unaryNodes++;
            sprintf(nodeType, "unary");
            break;
        case bg_NODE_TYPE_SUBGRAPH:
            err = bg_graph_generate(g, ((subgraph_data_t*)n->_priv_data)->subgraph, lvl+1);
            break;
        case bg_NODE_TYPE_DIVIDE:
        case bg_NODE_TYPE_SIN:
        case bg_NODE_TYPE_COS:
        case bg_NODE_TYPE_TAN:
        case bg_NODE_TYPE_ACOS:
        case bg_NODE_TYPE_ATAN2:
        case bg_NODE_TYPE_POW:
        case bg_NODE_TYPE_MOD:
        case bg_NODE_TYPE_ABS:
        case bg_NODE_TYPE_SQRT:
        case bg_NODE_TYPE_GREATER_THAN_0:
        case bg_NODE_TYPE_EQUAL_TO_0:
        case bg_NODE_TYPE_TANH:
        case bg_NODE_TYPE_FSIGMOID:
        case bg_NODE_TYPE_EXTERN:
            return bg_ERR_NOT_IMPLEMENTED;
        default:
            return bg_ERR_WRONG_TYPE;
    }

    suppress = 0;
    /*SPECIAL RULE 1: Suppress merge generation at toplvl INPUT nodes, instead we wire in_port to pipe*/
    if ((lvl == 0) && (n->type->id == bg_NODE_TYPE_INPUT))
    {
        addConnection(g, "external", g->toplvl_inputs, -1, nodeType, nodeId, 0);
        g->toplvl_inputs++;
        suppress = 1;
    }
    /*SPECIAL RULE 2: Suppress copy to edges at SUBGRAPH outputs*/
    if (n->type->id == bg_NODE_TYPE_SUBGRAPH)
        suppress = 1;
    // IV. Connect merges or sources to generated node (unless it has been suppressed)
    for (i = 0; (i < n->input_port_cnt) && !suppress; ++i)
    {
        if (n->input_ports[i]->num_edges > 0)
        {
            for (j = 0; j < n->input_ports[i]->num_edges; ++j)
                addConnection(g, "merge", mergeId[i], -1, nodeType, nodeId, i);
        } else {
            addConnection(g, "source", mergeId[i], -1, nodeType, nodeId, i);
        }
    }

    suppress = 0;
    /*SPECIAL RULE 2: Suppress copy to edges at SUBGRAPH outputs*/
    if (n->type->id == bg_NODE_TYPE_SUBGRAPH)
        suppress = 1;
    /*SPECIAL RULE 3: Suppress copy generation at toplvl OUTPUT nodes, instead we wire pipe to out_port*/
    if ((lvl == 0) && (n->type->id == bg_NODE_TYPE_OUTPUT))
    {
        addConnection(g, nodeType, nodeId, 0, "external", g->toplvl_outputs, -1);
        g->toplvl_outputs++;
        suppress = 1;
    }
    /*And put the result to all edges connected to the output(s)*/
    for (i = 0; (i < n->output_port_cnt) && !suppress; ++i)
    {
        for (j = 0; j < n->output_ports[i]->num_edges; ++j)
        {
            /*Check if edge has already been visited*/
            if (!bg_list_find(g->visited_edges, n->output_ports[i]->edges[j], &it))
            {
                /*Register edge, assign new id in increasing order*/
                edgeId = addEdge(g, n->output_ports[i]->edges[j]->weight, 0); /*Cannot be a back edge here!*/
                n->output_ports[i]->edges[j]->id = edgeId;
                bg_list_append(g->visited_edges, n->output_ports[i]->edges[j]);
            } else {
                edgeId = n->output_ports[i]->edges[j]->id;
            }
        }

        // VI. Generate copy or sink
        copyId[i] = addCopy(g, n->output_ports[i]->num_edges);

        // VII. connect copy or sink with generated node
        if (n->output_ports[i]->num_edges == 0)
            addConnection(g, nodeType, nodeId, i, "sink", copyId[i], -1);
        else
            addConnection(g, nodeType, nodeId, i, "copy", copyId[i], -1);

        // IIX. connect edges with copy (if sink, do nothing)
        for (j = 0; j < n->output_ports[i]->num_edges; ++j)
            addConnection(g, "copy", copyId[i], j, "edge", n->output_ports[i]->edges[j]->id, -1);
    }

    return err;
}

bg_error bg_graph_generate(bg_generator_t *g, bg_graph_t *graph, const unsigned int lvl)
{
    bg_error err = bg_SUCCESS;
    bg_node_t *current_node;
    bg_node_list_iterator_t it;

    /*Call bg_graph_evaluate to determine evaluation order (ONLY AT TOPLEVEL)*/
    if (lvl == 0)
    {
        err = bg_graph_evaluate(graph);
        if (err != bg_SUCCESS)
            return err;
    }

    /*Cycle through all nodes and call bg_node_generate*/
    for (current_node = bg_node_list_first(graph->evaluation_order, &it);
            current_node;
            current_node = bg_node_list_next(&it))
    {
        if ((err = bg_node_generate(g, current_node, lvl)) != bg_SUCCESS)
            return err;
        /*After we have generated a node we append it to the list of visited nodes. NEEDED for back edge detection!*/
        bg_list_append(g->visited_nodes, current_node);
        g->nodes++;
    }

    return err;
}

bg_error bg_generator_init(bg_generator_t *generator, FILE *fp, const char *name)
{
    dictEntry entry;

    generator->nodes = 0;
    generator->edges = 0;
    generator->sources = 0;
    generator->sinks = 0;
    generator->copies = 0;
    generator->merges = 0;
    generator->unaryNodes = 0;
    generator->connections = 0;
    generator->toplvl_inputs = 0;
    generator->toplvl_outputs = 0;
    generator->out = fp;

    sprintf(entry.token, "@name@");
    sprintf(entry.repl, "%s", name);
    writeDictionary(generator->out, &entry);

    bg_list_init(&generator->visited_edges);
    bg_list_init(&generator->visited_nodes);
    return bg_SUCCESS;
}

bg_error bg_generator_finalize(bg_generator_t *generator)
{
    dictEntry entry;
    time_t curr;
    time(&curr);

    /*Finalize connection section*/
    sprintf(entry.token, "@connection%u@", generator->connections);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize weight section*/
    sprintf(entry.token, "@weight%u@", generator->edges);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize edgeType section*/
    sprintf(entry.token, "@backEdge%u@", generator->edges);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize unary section*/
    sprintf(entry.token, "@unaryType%u@", generator->unaryNodes);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize srcValue section*/
    sprintf(entry.token, "@srcValue%u@", generator->sources);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize mergeType section*/
    sprintf(entry.token, "@mergeType%u@", generator->merges);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize mergeBias section*/
    sprintf(entry.token, "@mergeBias%u@", generator->merges);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize mergeInputs section*/
    sprintf(entry.token, "@mergeInputs%u@", generator->merges);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);
    /*Finalize copyOutputs section*/
    sprintf(entry.token, "@copyOutputs%u@", generator->copies);
    sprintf(entry.repl, "-- DONE");
    writeDictionary(generator->out, &entry);

    /*Add important values*/
    sprintf(entry.token, "@sources@");
    sprintf(entry.repl, "%u", generator->sources);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@sinks@");
    sprintf(entry.repl, "%u", generator->sinks);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@copies@");
    sprintf(entry.repl, "%u", generator->copies);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@merges@");
    sprintf(entry.repl, "%u", generator->merges);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@unaryNodes@");
    sprintf(entry.repl, "%u", generator->unaryNodes);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@edges@");
    sprintf(entry.repl, "%u", generator->edges);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@toplvlInputs@");
    sprintf(entry.repl, "%u", generator->toplvl_inputs);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@toplvlOutputs@");
    sprintf(entry.repl, "%u", generator->toplvl_outputs);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "@info@");
    sprintf(entry.repl, "GENERATED: %s", ctime(&curr));
    writeDictionary(generator->out, &entry);

    bg_list_deinit(generator->visited_edges);
    bg_list_deinit(generator->visited_nodes);
    fflush(generator->out);
    return bg_SUCCESS;
}

