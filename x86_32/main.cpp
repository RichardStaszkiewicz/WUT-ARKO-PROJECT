#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>

extern "C" int find_markers(unsigned char *bitmap, unsigned char *used, unsigned int *x_pos, unsigned int *y_pos, int width, int height);


int main(int argc, const char *argv[])
{
    // if (argc != 2)
    // {
    //     printf("Please provide only a path to the file\n");
    //     return 0;
    // }
    argv[1] = "./test_bmp/very_small.bmp";

    FILE *fp;
    fp = fopen(argv[1], "rb");

    if(fp == NULL){
        printf("Error: File not opened!\n");
        return 0;
    }

    unsigned char info[54];
    fread(info, sizeof(unsigned char), 54, fp);

    int width = *(int*)&info[18];
    int height = *(int*)&info[22];

    int size = width * height;
    unsigned char used[size];
    for(int i = 0; i < size/3; i++) used[i] = 0;
    size *= 3;
    unsigned char data[size];
    fread(data, sizeof(unsigned char), size, fp);
    unsigned int x_coord[1000000]; // amount of markers cannot be greater than 100
    unsigned int y_coord[1000000]; // amount of markers cannot be greater than 100
    // for(int i = 0; i < 30; i+=3) printf("%d %d %d\n", data[i], data[i+1], data[i+2]);

    fclose(fp);

    printf("%p\n", (void*) data);
    printf("%d %d %d\n", *(data), *(data + 1), *(data + 2));

    int amount = find_markers(data, used, x_coord, y_coord, width, height);


    printf("%p\n", (void*) x_coord);

    for(int i = 0; i < amount; i++) printf("(%d, %d)\n", x_coord[i], y_coord[i]);

    return 0;
}
