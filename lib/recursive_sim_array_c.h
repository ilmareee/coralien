typedef union {struct recursive_array* sub_array; short int* data;} array_data;

struct recursive_array
{
    array_data* upperright;  //most sub level array contain int*, 
    array_data* upperleft;   //others contains recursive_array* (or nullptr for uninitialized parts)
    array_data* downleft;    //which mean, along with the array must be passed
    array_data* downright;   //how much level of recusion he contain

    recursive_array* parent; //used for fast traversal, nullptr for the most outer one
};
