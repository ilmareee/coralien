#include "recursive_sim_array_c.h"
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>



cell* access(packaged_array arr,int x,int y)
//access a cell considering x/y 0 are upper left of array. try to acess parent if needed
//return NULL if unedefined (hitting a NULL while searching)
{
    recursive_array* array=arr.array;
    if (array == NULL){
        return NULL;
    }
    int size=1<<arr.level;
    while ((x<0) || (y<0) || (y>=size) || (x>=size)){ //x or y are out of bound, going upper in the recursive structure
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
    }
    while (size!=1){     //x and y are in this structure, finding in wich quarter
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
    //in fact, we are at lowest level, so this is a cell*, not a subarray
    return (cell*)array;
};
recursive_array* maybe_new_array(recursive_array* pointer)
//take a (potentially NULL) pointer to an recursive array, and return a valid one (to a new array if pointer was null)
{
    if (pointer==NULL){
        pointer=(recursive_array*)malloc(sizeof(recursive_array));
        if (pointer==NULL){
            printf("Not Enough RAM -- ABORTING");
            exit(-1);
        }
    }
    return pointer;
}


packaged_array define(packaged_array array,int x,int y,cell* new_cell)
//define cell considering x/y 0 are upper left of array.
//create parents/child if needed, and return new outmost array
//return {NULL,any int} if not enough RAM
{
    int size=1<<array.level;
    recursive_array* working_array=array.array;
    while ((x<0) || (y<0) || (y>=size) || (x>=size)){ //x or y are out of bound, going upper in the recursive structure
        array.array=(*working_array).parent;
        if (array.array == NULL){
            //TODO
        } else if (working_array==(*array.array).upright.sub_array){
            x-=size;
        } else if (working_array==(*array.array).downleft.sub_array){
            y-=size;
        } else if (working_array==(*array.array).downright.sub_array){
            x-=size;
            y-=size;
        }

        working_array=array.array;
        array.level+=1;
        size=size<<1;
    }
    recursive_array* newptr;
    while (size!=2){     //x and y are in this structure, finding in wich quarter
        size=size>>1;
        if (x>=size){
            x-=size;
            if (y>=size){
                y-=size;
                newptr=maybe_new_array((*working_array).downright.sub_array);
                (*working_array).downright.sub_array=newptr;
                working_array=newptr;
            } else {
                newptr=maybe_new_array((*working_array).upright.sub_array);
                (*working_array).upright.sub_array=newptr;
                working_array=newptr;
            }
        } else {
            if (y>=size){
                y-=size;
                newptr=maybe_new_array((*working_array).downleft.sub_array);
                (*working_array).downleft.sub_array=newptr;
                working_array=newptr;
            } else {
                newptr=maybe_new_array((*working_array).upleft.sub_array);
                (*working_array).upleft.sub_array=newptr;
                working_array=newptr;
            }
        }
    }

    //at this point x=0 or 1
    if (x==1){
            if (y==1){
                (*working_array).downright.data=new_cell;
            } else {
                (*working_array).upright.data=new_cell;
            }
        } else {
            if (y==1){
                (*working_array).downleft.data=new_cell;
            } else {
                (*working_array).upleft.data=new_cell;
            }
        }

    return array;
};