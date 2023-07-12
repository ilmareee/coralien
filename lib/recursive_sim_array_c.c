#include "recursive_sim_array_c.h"

cell zero_cell={0,0};
cell* zero_cell_ptr=&zero_cell;

cell* new_cell(short cur,short next)
//return a new cell with given cur and next values
{
    cell* pointer=(cell*)malloc(sizeof(cell));
    if (pointer==NULL){
        printf("Not Enough RAM -- ABORTING");
        exit(-1);
    }
    (*pointer).cur=cur;
    (*pointer).next=next;
    return pointer;
}


recursive_array* new_array(cell* cell_to_point)
//return a new empty array
{
    recursive_array* pointer=(recursive_array*)malloc(sizeof(recursive_array));
    if (pointer==NULL){
        printf("Not Enough RAM -- ABORTING");
        exit(-1);
    }
    *pointer=(recursive_array){{1,{.cel = cell_to_point}},{1,{.cel = cell_to_point}},{1,{.cel = cell_to_point}},{1,{.cel = cell_to_point}},NULL};
    return pointer;
}



const cell* access(packaged_array arr,int x,int y)
//access (readonly) a cell considering x/y 0 are upper left of array. try to acess parent if needed.
{
    recursive_array* array=arr.array;
    int size=1<<arr.level;
    while ((x<0) || (y<0) || (y>=size) || (x>=size)){ //x or y are out of bound, going upper in the recursive structure
        recursive_array* upper=(*array).parent;
        if (upper == NULL){
            return zero_cell_ptr;
        }
        if (array==(*upper).upright.value.arr){
            x-=size;
        } else if (array==(*upper).downleft.value.arr){
            y-=size;
        } else if (array==(*upper).downright.value.arr){
            x-=size;
            y-=size;
        }

        array=upper;
        size=size<<1;
    }
    while (true){     //x and y are in this structure, finding in wich quarter
        size=size>>1;
        if (x>=size){
            if (y>=size){
                if ((*array).downright.iscell){
                    return (*array).downright.value.cel;
                }
                array=(*array).downright.value.arr;
                y-=size;
            } else {
                if ((*array).upright.iscell){
                    return (*array).upright.value.cel;
                }
                array=(*array).upright.value.arr;
            }
            x-=size;
        } else {
            if (y>=size){
                if ((*array).downleft.iscell){
                    return (*array).downleft.value.cel;
                }
                array=(*array).downleft.value.arr;
                y-=size;
            } else {
                if ((*array).upleft.iscell){
                    return (*array).upleft.value.cel;
                }
                array=(*array).upleft.value.arr;
            }
        }
    }
};


packaged_array update(packaged_array array,int x,int y,short cur,short next)
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
                newptr=(*working_array).downright.sub_array;
                if (newptr==NULL){
                    newptr=new_array();
                    (*working_array).downright.sub_array=newptr;
                }
                working_array=newptr;
            } else {
                newptr=(*working_array).upright.sub_array;
                if (newptr==NULL){
                    newptr=new_array();
                    (*working_array).upright.sub_array=newptr;
                }
                working_array=newptr;
            }
        } else {
            if (y>=size){
                y-=size;
                newptr=(*working_array).downleft.sub_array;
                if (newptr==NULL){
                    newptr=new_array();
                    (*working_array).downleft.sub_array=newptr;
                }
                working_array=newptr;
            } else {
                newptr=(*working_array).upleft.sub_array;
                if (newptr==NULL){
                    newptr=new_array();
                    (*working_array).upleft.sub_array=newptr;
                }
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