
#include <stdbool.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct cell
{
    short int cur;
    short int next;
} cell;


typedef struct array_data {bool iscell;union {struct recursive_array* arr; cell* cel;} value;} array_data;

struct recursive_array
{
    array_data upright;     //
    array_data upleft;      //
    array_data downleft;    //along with the array must be passed
    array_data downright;   //how much level of recusion he contain

    recursive_array* parent; //used for fast traversal, nullptr for the most outer one
};

typedef recursive_array recursive_array;

typedef struct{recursive_array *array;short level;} packaged_array;

cell* new_cell(short cur,short next);