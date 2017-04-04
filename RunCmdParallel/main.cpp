/*
General purpose program to execute commands in a text file in parallel
*/

#include <cstdio>
#include <cstdlib>
#include <omp.h>
#include <vector>
#include <string>

using namespace std;

int main(int argc, char **argv)
{
   if(argc < 2) {
        printf("./%s commands.txt [CPU cores]\n", argv[0]);
        return 0;
    }

    int cores = omp_get_num_procs();

    if(argc == 3) {
        cores = atoi(argv[2]);
        if(cores <= 0) {
            fprintf(stderr, "[RunCmdParalle] Invalid number of cores\n");
            return -1;
        }
    }

    omp_set_num_threads(cores);

    //printf("RunCmdParallel cores: %d\n", cores);

    char line[1024];
    FILE *fp = fopen(argv[1], "r");

    if(fp == NULL) {
        fprintf(stderr, "[RunCmdParallel] Error opening input: %s\n", argv[1]);
        return -1;
    }

    vector <string> cmds;
    while(fgets(line, sizeof(line), fp)) {
        cmds.push_back(string(line));
    }

    #pragma omp parallel for
    for(int i=0; i < (int)cmds.size(); i++) {
        system(cmds[i].c_str());
    }

    fclose(fp);

    return 0;
}
