#include "Timing.h"

double TimeDiff(timeval t1, timeval t2)
{
    double t;
    t = (t2.tv_sec - t1.tv_sec) * 1000.0;      // sec to ms
    t += (t2.tv_usec - t1.tv_usec) / 1000.0;   // us to ms

    return t;
}
