/*
 *  Copyright (c) 2008-2010  Noah Snavely (snavely (at) cs.cornell.edu)
 *    and the University of Washington
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 */

/* KeyMatchFull.cpp */
/* Read in keys, match, write results to a file */

// Modified by Nghia Ho - added multi-core support, replaced ANN with FLANN

#include <assert.h>
#include <time.h>
#include <string.h>
#include <string>
#include <vector>
#include <omp.h>
#include <cstdio>
#include <iostream>
#include <boost/filesystem.hpp>
#include <flann/flann.hpp>

#include "keys2a.h"
#include "Timing.h"

using namespace std;
using namespace boost::filesystem;

int main(int argc, char **argv) {
    char *list_in;
    char *file_out;
    double ratio = 0.6;
    int max_seq = -1;
    int c;
    bool recovery_mode = false;
    int recovered_i = 0, recovered_j=0;
    char filename[1024];
    char line[1024];

    if (argc < 3) {
        printf("Usage: ./SiftMatcher [options] list_keys.txt matches.txt\n");
        printf("Options are:\n\n");
        printf("-s [num]    Sequential matching, match current image to last [num] image\n");
        printf("-r          Recovery mode. Uses SiftMatcher.log to resume from last incomplete run of SiftMatcher.\n");
        printf("\n");

        return -1;
    }

    while ((c = getopt (argc, argv, "s:r")) != -1) {
        switch (c) {
            case 's':
            max_seq = atoi(optarg);
            if(max_seq <= 0 && max_seq != -1) {
                fprintf(stderr, "Invalid value for sequential matching\n");
                return -1;
            }
            break;

            case 'r':
            recovery_mode = true;
            break;

            case '?':
            if (optopt == 's') {
               fprintf(stderr, "Option -%c requires an argument.\n", optopt);
               return -1;
            }

            default:
            fprintf(stderr, "Invalid option\n");
            return -1;
        }
    }

    if(argc - optind != 2) {
        printf("Missing input and output file\n");
        return -1;
    }

    list_in = argv[optind];
    file_out = argv[optind+1];

    if(max_seq == -1) {
        printf("[SiftMatcher] Using all images for matching\n");
    }
    else {
        printf("[SiftMatcher] Using a maximum of %d images for matching\n", max_seq);
    }

    if(recovery_mode) {
        FILE *fp = fopen("SiftMatcher.log", "r");

        if(fp == NULL) {
            fprintf(stderr, "No SiftMatcher.log found for recovery. But that's okay!\n");
        }
        else {
            fgets(line, sizeof(line), fp);
            sscanf(line, "%d %d %d", &max_seq, &recovered_i, &recovered_j);
            fclose(fp);

            printf("[SiftMatcher] Recovering from image %d matching to %d\n", recovered_i, recovered_j);
        }
    }

    timeval start, end;

    //unsigned char **keys;
    //int *num_keys;

    /* Read the list of files */
    std::vector<std::string> key_files;

    FILE *f = fopen(list_in, "r");
    if (f == NULL) {
        fprintf(stderr, "Error opening file %s for reading\n", list_in);
        return 1;
    }

    char buf[512];
    while (fgets(buf, 512, f)) {
        /* Remove trailing newline */
        if (buf[strlen(buf) - 1] == '\n')
            buf[strlen(buf) - 1] = 0;

        key_files.push_back(std::string(buf));
    }

    fclose(f);

    f = fopen(file_out, "w");
    assert(f != NULL);


    int num_images = (int) key_files.size();


//    keys = new unsigned char *[num_images];
//    num_keys = new int[num_images];

    /* Read all keys */
    // BAD IDEA FOR BIG DATASET
    /*
    for (int i = 0; i < num_images; i++) {
        keys[i] = NULL;
        num_keys[i] = ReadKeyFile(key_files[i].c_str(), keys+i);
        printf("[SiftMatcher] Reader %d/%d\n", i+1, num_images);
    }
    */

    #pragma omp parallel for schedule(dynamic)
    for (int i = recovered_i; i < num_images; i++) {
        unsigned char *keys_i;
        int num_keys_i = ReadKeyFile(key_files[i].c_str(), &keys_i);

        if (num_keys_i == 0)
            continue;

        char dir[1024];
        sprintf(dir, "%06d", i);

        path data_dir(dir);
        if(!is_directory(data_dir)) {
            printf("[SiftMatcher] Creating directory: %s\n", dir);
            create_directory(dir);
        }

        gettimeofday(&start, NULL);

        vector <float> data(num_keys_i*128);
        for(int j=0; j < num_keys_i; j++) {
            for(int k=0; k < 128; k++) {
                data[j*128 + k] = keys_i[j*128 + k];
            }
        }

        flann::Matrix <float> dataset(&data[0], num_keys_i, 128);
        flann::Index < flann::L2<float> > index(dataset, flann::KDTreeIndexParams(4));
        index.buildIndex();

        int j_start = 0;

        if(recovery_mode) {
            j_start = recovered_j;
            recovery_mode = false;
        }

        if(max_seq != -1) {
           j_start = i - max_seq;

            if(j_start < 0) {
                j_start = 0;
            }
        }

        vector <char> completed_j(i-j_start, 0);

        for (int j = j_start; j < i; j++) {
            unsigned char *keys_j;
            int num_keys_j = ReadKeyFile(key_files[j].c_str(), &keys_j);

            if (num_keys_j == 0)
                continue;

            printf("[SiftMatcher] Matching image %d to %d\n", i, j);

            /* Compute likely matches between two sets of keypoints */

            int num_queries = num_keys_j;

            vector <float> queries_data(num_queries*128);
            for(int k=0; k < num_queries; k++) {
                for(int l=0; l < 128; l++) {
                    queries_data[k*128 + l] = keys_j[k*128 + l];
                }
            }

            int nn = 2;
            vector <int> indices_data(num_queries*nn);
            vector <float> dists_data(num_queries*nn);

            flann::Matrix<float> queries(&queries_data[0], num_queries, 128);
            flann::Matrix<int> indices(&indices_data[0], num_queries, nn);
            flann::Matrix<float> dists(&dists_data[0], num_queries, nn);

            index.knnSearch(queries, indices, dists, nn, flann::SearchParams(128));

            vector <KeypointMatch> matches;
            for(int k=0; k < num_queries; k++) {
                float dist1 = dists_data[k*2];
                float dist2 = dists_data[k*2 + 1];

                if(dist1 < dist2*ratio) {
                    KeypointMatch kp(k, indices_data[k*2]);
                    matches.push_back(kp);
                }
            }

            if(matches.size() >= 16) {
                sprintf(filename, "%06d/SiftMatcher_%d_%d.txt", i, i, j);

                FILE *fp = fopen(filename, "w+");
                if(fp == NULL) {
                    fprintf(stderr, "Can't open %s for writing\n", filename);
                    exit(-1);
                }

                fprintf(fp, "%d %d\n", j, i);
                fprintf(fp, "%d\n", (int)matches.size());

                for(size_t k = 0; k < matches.size(); k++) {
                    fprintf(fp, "%d %d\n", matches[k].m_idx1, matches[k].m_idx2);
                }

                fflush(fp);
                fclose(fp);
            }

            completed_j[j - j_start] = 1;

            // Due to the use of OpenMP we have to find the safe completed j to log
            int last_j=0;
            for(size_t k=0; k < completed_j.size(); k++) {
                if(completed_j[k]) {
                    last_j = j_start + k;
                }
                else {
                    break;
                }
            }

            delete [] keys_j;

            // Write completed index to log file
            FILE *fp = fopen("SiftMatcher.log", "w+");
            fprintf(fp, "%d %d %d", max_seq, i, last_j);
            fclose(fp);
        }

        delete [] keys_i;

        gettimeofday(&end, NULL);
        fflush(stdout);
    }

    // Combine all the resulting txt files
    for(int i=0; i < num_images; i++) {
        for (int j=0; j < i; j++) {
            sprintf(filename, "%06d/SiftMatcher_%d_%d.txt", i, i, j);

            // Check if the file exists
            FILE *fp = fopen(filename, "r");
            if(fp == NULL) {
                continue;
            }

            while(fgets(line, sizeof(line), fp)) {
                fprintf(f, "%s", line);
            }

            fclose(fp);
        }
    }

    fclose(f);

    return 0;
}
