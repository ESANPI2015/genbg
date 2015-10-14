#include "bagel.h"
#include "bg_generate2.h"
#include "node_types/bg_node_subgraph.h"
#include "node_list.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "template_engine.h"

/*This function generates dictionary entries for each code line*/
static void code(bg_generator_t *g, const char* src)
{
    dictEntry entry;

    sprintf(entry.token, "<code%u>", g->code_lines);
    snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%s\n<code%u>", src, g->code_lines+1);
    writeDictionary(g->out, &entry);
    g->code_lines++;
}

/*This function generated a dictionary entry for each weight*/
static void weight(bg_generator_t *g, const int index, const float value, const int final)
{
    dictEntry entry;

    sprintf(entry.token, "<weight%u>", index);
    if (final)
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%ff", value);
    else
        snprintf(entry.repl, TEMPLATE_ENGINE_MAX_STRING_LENGTH, "%ff,\n<weight%u>", value, index+1);
    writeDictionary(g->out, &entry);
}

bg_error bg_merge_generate (bg_generator_t *g, struct input_port_t *input_port, const int id, const unsigned int lvl)
{
    bg_error err = bg_SUCCESS;
    bg_list_iterator_t it;
    int j;
    int edgeId;
    char line[TEMPLATE_ENGINE_MAX_STRING_LENGTH];

    code(g,"\t/*** MERGE GENERATOR BEGIN ***/");

    /*Initialization*/
    switch (input_port->merge->id)
    {
        case bg_MERGE_TYPE_MAX:
        case bg_MERGE_TYPE_MIN:
        case bg_MERGE_TYPE_PRODUCT:
        case bg_MERGE_TYPE_SUM:
            sprintf(line, "\tmerge[%u] = %ff;", id, input_port->bias);
            code(g, line);
            break;
        case bg_MERGE_TYPE_WEIGHTED_SUM:
            sprintf(line, "\tfloat sum_weights = 0.0f;");
            code(g, line);
            sprintf(line, "\tmerge[%u] = 0.f;", id);
            code(g, line);
            break;
        case bg_MERGE_TYPE_MEAN:
            sprintf(line, "\tint cnt = 0;");
            code(g, line);
            sprintf(line, "\tmerge[%u] = 0.f;", id);
            code(g, line);
            break;
        case bg_MERGE_TYPE_NORM:
            sprintf(line, "\tmerge[%u] = %ff * %ff;", id, input_port->bias, input_port->bias);
            code(g, line);
            break;
        case bg_MERGE_TYPE_MEDIAN:
            return bg_ERR_NOT_IMPLEMENTED;
        default:
            return bg_ERR_WRONG_TYPE;
    }

    if (input_port->num_edges == 0)
    {
        /*No incoming edges*/
        switch (input_port->merge->id)
        {
            case bg_MERGE_TYPE_MEAN:
            case bg_MERGE_TYPE_PRODUCT:
            case bg_MERGE_TYPE_SUM:
                sprintf(line, "\tmerge[%u] += %ff;", id, input_port->defaultValue);
                code(g, line);
                break;
            case bg_MERGE_TYPE_WEIGHTED_SUM:
                sprintf(line, "\tsum_weights = 1.0f;");
                code(g, line);
                break;
            case bg_MERGE_TYPE_MIN:
                sprintf(line, "\tmerge[%u] = (merge[%u] > %ff) ? %ff : merge[%u];",
                        id, 
                        id, 
                        input_port->defaultValue,
                        input_port->defaultValue,
                        id
                        );
                code(g, line);
                break;
            case bg_MERGE_TYPE_MAX:
                sprintf(line, "\tmerge[%u] = (merge[%u] < %ff) ? %ff : merge[%u];",
                        id, 
                        id, 
                        input_port->defaultValue,
                        input_port->defaultValue,
                        id
                        );
                code(g, line);
                break;
            case bg_MERGE_TYPE_NORM:
                sprintf(line, "\tmerge[%u] += %ff * %ff;", id, input_port->defaultValue, input_port->defaultValue);
                code(g, line);
                break;
            case bg_MERGE_TYPE_MEDIAN:
                return bg_ERR_NOT_IMPLEMENTED;
            default:
                return bg_ERR_WRONG_TYPE;
        }
    } else {
        /*Cycle through all connected edges
         * if new edge, add to list and give id
         * if not, get id*/
        for (j = 0; j < input_port->num_edges; ++j)
        {
            /*Check if edge has already been visited*/
            if (!bg_list_find(g->visited_edges, input_port->edges[j], &it))
            {
                /*Register edge, assign new id in increasing order*/
                edgeId = g->edges++;
                input_port->edges[j]->id = edgeId;
                bg_list_append(g->visited_edges, input_port->edges[j]);
            } else {
                edgeId = input_port->edges[j]->id;
            }

            /*Add merge specific code here!!!*/
            switch (input_port->merge->id)
            {
                case bg_MERGE_TYPE_SUM:
                    sprintf(line, "\tmerge[%u] += edgeValue[%u] * edgeWeight[%u];", id, edgeId, edgeId);
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_WEIGHTED_SUM:
                    sprintf(line, "\tsum_weights += fabsf(edgeWeight[%u]);", edgeId);
                    code(g, line);
                    sprintf(line, "\tmerge[%u] += edgeValue[%u] * edgeWeight[%u];", id, edgeId, edgeId);
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_PRODUCT:
                    sprintf(line, "\tmerge[%u] *= edgeValue[%u] * edgeWeight[%u];", id, edgeId, edgeId);
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_MIN:
                    sprintf(line, "\tmerge[%u] = (edgeValue[%u] * edgeWeight[%u] < merge[%u]) ? edgeValue[%u] * edgeWeight[%u] : merge[%u];",
                            id, 
                            edgeId, 
                            edgeId,
                            id, 
                            edgeId, 
                            edgeId,
                            id
                            );
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_MAX:
                    sprintf(line, "\tmerge[%u] = (edgeValue[%u] * edgeWeight[%u] > merge[%u]) ? edgeValue[%u] * edgeWeight[%u] : merge[%u];",
                            id, 
                            edgeId, 
                            edgeId,
                            id, 
                            edgeId, 
                            edgeId,
                            id
                            );
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_MEAN:
                    sprintf(line, "\tcnt++;");
                    code(g, line);
                    sprintf(line, "\tmerge[%u] += edgeValue[%u] * edgeWeight[%u];", id, edgeId, edgeId);
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_NORM:
                    sprintf(line, "\tmerge[%u] += edgeValue[%u] * edgeValue[%u] * edgeWeight[%u] * edgeWeight[%u];",
                            id,
                            edgeId,
                            edgeId,
                            edgeId,
                            edgeId
                            );
                    code(g, line);
                    break;
                case bg_MERGE_TYPE_MEDIAN:
                    return bg_ERR_NOT_IMPLEMENTED;
                default:
                    return bg_ERR_WRONG_TYPE;
            }
        }
    }
    /*Finalization*/
    switch (input_port->merge->id)
    {
        case bg_MERGE_TYPE_MAX:
        case bg_MERGE_TYPE_MIN:
        case bg_MERGE_TYPE_PRODUCT:
        case bg_MERGE_TYPE_SUM:
            break;
        case bg_MERGE_TYPE_WEIGHTED_SUM:
            sprintf(line, "\tmerge[%u] = (sum_weights > %f) ? merge[%u] / sum_weights : 0.f;",
                    id,
                    bg_EPSILON,
                    id
                    );
            code(g, line);
            sprintf(line, "\tmerge[%u] += %ff;",
                    id,
                    input_port->bias
                    );
            code(g, line);
            break;
        case bg_MERGE_TYPE_MEAN:
            sprintf(line, "\tmerge[%u] = (cnt > 1) ? merge[%u] / cnt : merge[%u];",
                    id,
                    id,
                    id
                    );
            code(g, line);
            sprintf(line, "\tmerge[%u] += %ff;",
                    id,
                    input_port->bias
                    );
            code(g, line);
            break;
        case bg_MERGE_TYPE_NORM:
            sprintf(line, "\tmerge[%u] = sqrtf(merge[%u]);",
                    id,
                    id
                    );
            code(g, line);
            break;
        case bg_MERGE_TYPE_MEDIAN:
            return bg_ERR_NOT_IMPLEMENTED;
        default:
            return bg_ERR_WRONG_TYPE;
    }
    code(g,"\t/*** MERGE GENERATOR END ***/");

    return err;
}

bg_error bg_node_generate(bg_generator_t *g, bg_node_t *n, const unsigned int lvl)
{
    bg_error err = bg_SUCCESS;
    bg_list_iterator_t it;
    int i,j;
    int edgeId;
    char line[TEMPLATE_ENGINE_MAX_STRING_LENGTH];
    int suppress = 0;

    code(g,"\t/*** BG_NODE_GENERATE BEGIN ***/");

    /*At first we have to generate merges for each node input*/
    /*SPECIAL RULE 1: Suppress merge generation at toplvl INPUT nodes*/
    if ((lvl == 0) && (n->type->id == bg_NODE_TYPE_INPUT))
        suppress = 1;
    /*SPECIAL RULE 2: Suppress merge generation at SUBGRAPH inputs*/
    if (n->type->id == bg_NODE_TYPE_SUBGRAPH)
        suppress = 1;
    for (i = 0; (i < n->input_port_cnt) && !suppress; ++i)
    {
        if ((err = bg_merge_generate(g, n->input_ports[i], i, lvl)) != bg_SUCCESS)
            return err;
    }

    suppress = 0;
    /*Then we have to pass the results to the node function*/
    switch (n->type->id)
    {
        case bg_NODE_TYPE_INPUT:
            if (lvl == 0)
            {
                sprintf(line, "\tresult = in[%u];", g->toplvl_inputs++);
                code(g, line);
            } else {
                code(g,"\tresult = merge[0];");
            }
            break;
        case bg_NODE_TYPE_OUTPUT:
            if (lvl == 0)
            {
                sprintf(line, "\tout[%u] = merge[0];", g->toplvl_outputs++);
                code(g, line);
            } else {
                code(g,"\tresult = merge[0];");
            }
            break;
        case bg_NODE_TYPE_PIPE:
            code(g,"\tresult = merge[0];");
            break;
        case bg_NODE_TYPE_DIVIDE:
            code(g,"\tresult = 1.f / merge[0];");
            break;
        case bg_NODE_TYPE_SIN:
            code(g,"\tresult = sinf(merge[0]);");
            break;
        case bg_NODE_TYPE_COS:
            code(g,"\tresult = cosf(merge[0]);");
            break;
        case bg_NODE_TYPE_TAN:
            code(g,"\tresult = tanf(merge[0]);");
            break;
        case bg_NODE_TYPE_ACOS:
            code(g,"\tresult = acosf(merge[0]);");
            break;
        case bg_NODE_TYPE_ATAN2:
            code(g,"\tresult = atan2f(merge[0], merge[1]);");
            break;
        case bg_NODE_TYPE_POW:
            code(g,"\tresult = powf(merge[0], merge[1]);");
            break;
        case bg_NODE_TYPE_MOD:
            code(g,"\tresult = fmodf(merge[0], merge[1]);");
            break;
        case bg_NODE_TYPE_ABS:
            code(g,"\tresult = fabsf(merge[0]);");
            break;
        case bg_NODE_TYPE_SQRT:
            code(g,"\tresult = sqrtf(merge[0]);");
            break;
        case bg_NODE_TYPE_GREATER_THAN_0:
            code(g,"\tresult = (merge[0] > 0.f) ? merge[1] : merge[2];");
            break;
        case bg_NODE_TYPE_EQUAL_TO_0:
            sprintf(line, "\tresult = (fabsf(merge[0]) < %ff) ? merge[1] : merge[2];",
                    bg_EPSILON
                   );
            code(g, line);
            break;
        case bg_NODE_TYPE_TANH:
            code(g,"\tresult = tanhf(merge[0]);");
            break;
        case bg_NODE_TYPE_SUBGRAPH:
            code(g,"\t/*** SUBGRAPH START ***/");
            err = bg_graph_generate(g, ((subgraph_data_t*)n->_priv_data)->subgraph, lvl+1);
            code(g,"\t/*** SUBGRAPH END ***/");
            break;
        case bg_NODE_TYPE_FSIGMOID:
        case bg_NODE_TYPE_EXTERN:
            return bg_ERR_NOT_IMPLEMENTED;
        default:
            return bg_ERR_WRONG_TYPE;
    }

    /*And put the result to all edges connected to the output(s)*/
    /*SPECIAL RULE 2: Suppress copy to edges at SUBGRAPH outputs*/
    if (n->type->id == bg_NODE_TYPE_SUBGRAPH)
        suppress = 1;
    for (i = 0; (i < n->output_port_cnt) && !suppress; ++i)
    {
        for (j = 0; j < n->output_ports[i]->num_edges; ++j)
        {
            /*Check if edge has already been visited*/
            if (!bg_list_find(g->visited_edges, n->output_ports[i]->edges[j], &it))
            {
                /*Register edge, assign new id in increasing order*/
                edgeId = g->edges++;
                n->output_ports[i]->edges[j]->id = edgeId;
                bg_list_append(g->visited_edges, n->output_ports[i]->edges[j]);
            } else {
                edgeId = n->output_ports[i]->edges[j]->id;
            }
            sprintf(line, "\tedgeValue[%u] = result;", edgeId);
            code(g, line);
        }
    }

    code(g,"\t/*** BG_NODE_GENERATE END ***/");

    return err;
}

bg_error bg_graph_generate(bg_generator_t *g, bg_graph_t *graph, const unsigned int lvl)
{
    bg_error err = bg_SUCCESS;
    bg_node_t *current_node;
    bg_node_list_iterator_t it;

    code(g,"\t/*** BG_GRAPH_GENERATE BEGIN ***/");

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
        g->nodes++;
    }

    code(g,"\t/*** BG_GRAPH_GENERATE END ***/");

    return err;
}

bg_error bg_generator_init(bg_generator_t *generator, FILE *fp, const char *name)
{
    dictEntry entry;

    generator->nodes = 0;
    generator->edges = 0;
    generator->code_lines = 0;
    generator->toplvl_inputs = 0;
    generator->toplvl_outputs = 0;
    generator->out = fp;

    sprintf(entry.token, "<name>");
    sprintf(entry.repl, "%s", name);
    writeDictionary(generator->out, &entry);

    bg_list_init(&generator->visited_edges);
    return bg_SUCCESS;
}

bg_error bg_generator_finalize(bg_generator_t *generator)
{
    bg_edge_t *edge = NULL;
    bg_list_iterator_t it;
    dictEntry entry;
    int edgeId;

    /*Finalize code section*/
    sprintf(entry.token, "<code%u>", generator->code_lines);
    sprintf(entry.repl, "\t/*DONE*/");
    writeDictionary(generator->out, &entry);

    /*Generate weights*/
    for (edge = bg_list_first(generator->visited_edges, &it);
            edge;
            edge = bg_list_next(&it))
    {
        edgeId = edge->id;
        if (edgeId < generator->edges-1)
            weight(generator, edgeId, edge->weight, 0);
        else
            weight(generator, edgeId, edge->weight, 1);
    }

    /*Add important values*/
    sprintf(entry.token, "<type>");
    sprintf(entry.repl, "float");
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "<nodes>");
    sprintf(entry.repl, "%u", generator->nodes);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "<edges>");
    sprintf(entry.repl, "%u", generator->edges);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "<toplvlInputs>");
    sprintf(entry.repl, "%u", generator->toplvl_inputs);
    writeDictionary(generator->out, &entry);

    sprintf(entry.token, "<toplvlOutputs>");
    sprintf(entry.repl, "%u", generator->toplvl_outputs);
    writeDictionary(generator->out, &entry);

    bg_list_deinit(generator->visited_edges);
    fflush(generator->out);
    return bg_SUCCESS;
}
