/*
 * *** DO NOT MODIFY ***
 */

#include "<name>.h"
#include <math.h>

/*
 * CONST REGION:
 * contains edge weights
 * NOTE: This will be in ROM!
 */
const <type> edgeWeight[<name>_NO_EDGES] =
{
    /*
     * FORMAT:
     * value of type <type>,
     */
<weight0>
};

/*
 * STATIC REGION:
 * contains current edge values
 * NOTE: This is the only stuff held in RAM!
 */
static <type> edgeValue[<name>_NO_EDGES] = {0.f};

/*
 * FUNCTION REGION
 */
int <name>_evaluate (const <type> in[<name>_NO_INPUTS], <type> out[<name>_NO_OUTPUTS])
{
    <type> result;
    <type> merge[3];

<code0>

    return 0;
}
