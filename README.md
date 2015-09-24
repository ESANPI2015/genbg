-=Distributed Behaviour Graphs=-

This work is based on the behaviour graphs introduced by Malte Langosz, DFKI.
Originally, these graphs are topologically sorted and executed according to the sorting.
The nodes of the graph are therefore evaluated as if they would follow homogeneous static dataflow semantics.
In principle, the BGs represent one sequential piece of code.

The semantics of the BGs shall be extended such, that concurrent evaluations are possible and the graph can be partioned such that the partitions/compositions can be distributed across multiple
processing entities (e.g. threads, processes etc.).
The idea:
* Assign a FSM representation to each atomic actor
* Model the links between actors as FSM as well
* Composition means parallel composition of the included (atomic) components and the links to derive a compositional FSM representation
  (this will enable compositional verification techniques in the end).
* From FSM models code will be generated as templates for implementation (either C language or VHDL language)

This is just proof-of-concept software which gives hints about how to extend the ROCK framework to support heterogenous, distributed systems in a consistent manner.

-=Status=-

DONE:
* There is a behaviour graph to C generator
  - bg2dict_c generates a dictionary from behaviour graph spec (C language)
  - dict2src is a template engine using a dictionary and a template to generate src/header files
  - Templates: 
     * include/bg_generate_header_template.h
     * src/bg_generate_source_template.c

* The generated files are a standalone version of a behaviour graph
