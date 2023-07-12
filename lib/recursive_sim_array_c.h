typedef struct
{
    short int cur;
    short int next;
} cell;


typedef union {struct recursive_array* sub_array; cell* data;} array_data;

struct recursive_array
{
    array_data upright;     //most sub level array contain cell*, (level 1)
    array_data upleft;      //others contains recursive_array* (or nullptr for uninitialized parts)
    array_data downleft;    //which mean, along with the array must be passed
    array_data downright;   //how much level of recusion he contain

    recursive_array* parent; //used for fast traversal, nullptr for the most outer one
};

typedef recursive_array recursive_array;

typedef struct{recursive_array *array;short level;} packaged_array;