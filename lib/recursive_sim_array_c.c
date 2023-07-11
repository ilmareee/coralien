#include "recursive_sim_array_c.h"
#include <unistd.h>



cell* access(recursive_array* array,short level,int x,int y)
//access a cell considering x/y 0 are upper left of array. try to acess parent if needed
//return NULL if unedefined (hitting a NULL while searching)
{
    if (array == NULL){
        return NULL;
    }
    int size=1<<level;
    while (size!=1){
        if ((x<0) || (y<0) || (y>=size) || (x>=size)){ //x or y are out of bound, going upper in the recursive structure
            recursive_array* upper=(*array).parent;
            if (upper == NULL){
                return NULL;
            }
            if (array==(*upper).upright.sub_array){
                x-=size;
            } else if (array==(*upper).downleft.sub_array){
                y-=size;
            } else if (array==(*upper).downright.sub_array){
                x-=size;
                y-=size;
            }

            array=upper;
            size=size<<1;
        } else {     //x and y are in this structure, finding in wich quarter
            size=size>>1;
            if (x>=size){
                x-=size;
                if (y>=size){
                    y-=size;
                    array=(*array).downright.sub_array;
                } else {
                    array=(*array).upright.sub_array;
                }
            } else {
                if (y>=size){
                    y-=size;
                    array=(*array).downleft.sub_array;
                } else {
                    array=(*array).upleft.sub_array;
                }
            }
            if (array==NULL){
                return NULL;
            }
        }
    }
    //in fact, we are at lowest level, so this is a cell*, not a subarray
    return (cell*)array;
};