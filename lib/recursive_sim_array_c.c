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
array_data makedata(recursive_array* pointer){
    return (array_data){false,{.arr=pointer}};
}
array_data makedata(cell* pointer){
    return (array_data){false,{.cel=pointer}};
}
array_data makedata(short value){
    return (array_data){true,{.special=value}};
}
array_data makedata(int value){
    return (array_data){true,{.special=value}};
}
recursive_array* new_array(array_data upright,array_data upleft,array_data downright,array_data downleft,recursive_array* parent)
//return a new array
{
    recursive_array* pointer=(recursive_array*)malloc(sizeof(recursive_array));
    if (pointer==NULL){
        printf("Not Enough RAM -- ABORTING");
        exit(-1);
    }
    *pointer=(recursive_array){upright,upleft,downright,downleft,parent};
    return pointer;
}
recursive_array* new_spe_array(short val,recursive_array* parent){
    recursive_array* pointer=(recursive_array*)malloc(sizeof(recursive_array));
    if (pointer==NULL){
        printf("Not Enough RAM -- ABORTING");
        exit(-1);
    }
    array_data data=makedata(val);
    *pointer=(recursive_array){data,data,data,data,parent};
    return pointer;
}


short read(packaged_array arr,int x,int y)
//access (readonly) a cell considering x/y 0 are upper left of array. try to acess parent if needed.
{
    recursive_array* array=arr.array;
    int size=1<<arr.level;
    while ((x<0) || (y<0) || (y>=size) || (x>=size)){ //x or y are out of bound, going upper in the recursive structure
        recursive_array* upper=array->parent;
        if (upper == NULL){
            return 0;
        }
        if (array==upper->upright.value.arr){
            x+=size;
        } else if (array==upper->downleft.value.arr){
            y+=size;
        } else if (array==upper->downright.value.arr){
            x+=size;
            y+=size;
        }

        array=upper;
        size=size<<1;
    }
    array_data* selected;
    while (size>1){     //x and y are in this structure, finding in wich quarter
        size=size>>1;
        if (x>=size){
            if (y>=size){
                selected=&array->downright;
                y-=size;
            } else {
                selected=&array->upright;
            }
            x-=size;
        } else {
            if (y>=size){
                selected=&array->downleft;
                y-=size;
            } else {
                selected=&array->upleft;
            }
        }
        if (selected->isspecial){
            return selected->value.special;
        }
        array=selected->value.arr;
    }
    //in fact we are at lowest level, array contain a cell*
    return ((cell*)array)->cur;
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
            if (x<0){
                x+=size;
                if (y<0){
                    y+=size;
                    array.array=new_array(makedata(0),makedata(0),makedata(0),makedata(working_array),NULL);
                } else {
                    array.array=new_array(makedata(0),makedata(working_array),makedata(0),makedata(0),NULL);
                }
            } else {
                if (y<0){
                    y+=size;
                    array.array=new_array(makedata(0),makedata(0),makedata(working_array),makedata(0),NULL);
                } else {
                    array.array=new_array(makedata(working_array),makedata(0),makedata(0),makedata(0),NULL);
                }
            }
        (*working_array).parent=array.array;

        } else if ((!(*array.array).upright.isspecial) && working_array==(*array.array).upright.value.arr){
            x+=size;
        } else if ((!(*array.array).downleft.isspecial) && working_array==(*array.array).downleft.value.arr){
            y+=size;
        } else if ((!(*array.array).downright.isspecial) && working_array==(*array.array).downright.value.arr){
            x+=size;
            y+=size;
        }

        working_array=array.array;
        array.level+=1;
        size=size<<1;
    }
    array_data *selected;
    while (size>1){     //x and y are in this structure, finding in wich quarter
        size=size>>1;
        if (x>=size){
            x-=size;
            if (y>=size){
                y-=size;
                selected=&working_array->downright;
            } else {
                selected=&working_array->upright;
            }
        } else {
            if (y>=size){
                y-=size;
                selected=&working_array->downleft;
                
            } else {
                selected=&working_array->upleft;
            }
        }
        if (selected->isspecial){
                    selected->isspecial=false;
                    selected->value.arr=new_spe_array(selected->value.special,working_array);
                }
                working_array=selected->value.arr;
    }
    //size=1, x and y = 0 or 1
    if (x==1){
        if (y==1){
            selected=&working_array->downright;
        } else {
            selected=&working_array->upright;
        }
    } else {
        if (y==1){
            selected=&working_array->downleft;
        } else {
            selected=&working_array->upleft;
        }
    }
    if (selected->isspecial){
        selected->isspecial=false;
        selected->value.cel=new_cell(cur,next);
    } else {
        selected->value.cel->cur=cur;
        selected->value.cel->next=next;
    }

    return array;
};

