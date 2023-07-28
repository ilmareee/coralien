# cython: nonecheck=False
# cython: language_level=3str
import numpy as np
cimport numpy as cnp
cimport cython


cnp.import_array()
DTYPE = np.int16
ctypedef cnp.int16_t DTYPE_t


@cython.boundscheck(False) # turn off bounds-checking for entire function
@cython.wraparound(False)  # turn off negative index wrapping for entire function
cdef DTYPE_t simulate_one(const DTYPE_t[:,:] cells) nogil:
    #cells should be a 3*3 memoryview, return new cell value
    return cells[1,1]

chunksize:int=0
cdef short cchunksize=0

cdef class chunk:
    cdef DTYPE_t[:,:,:] memview
    def __init__(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:

        cdef cnp.ndarray nparray=np.zeros((chunk.size,chunk.size,2),dtype=DTYPE)
        self.nparray=nparray
        self.memview=self.nparray

    #def add_voisins(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:
    #    if up!=None:
    #        self.up=up
    #    if down!=None:
    #        self.down=down
    #    if right!=None:
    #        self.right=right
    #    if left!=None:
    #        self.left=left
   # 
    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    cdef bint simulate(self,isodd:cython.bint) nogil:
        #on ODD: [:,:,1]->[:,:,0], reverse on non ODD
        #return true if at least one cell is alive
        cdef short source,dest
        if isodd:
            source=1
            dest=0
        else:
            source=0
            dest=1

        cdef short x,y,looprange
        looprange=cchunksize+1
        for x in range(1,looprange):
            for y in range(1,looprange):
                simulate_one(self.memview[x-1:x+1,y-1:y+1,source])

    def py_direct_simulate(self,isodd:bool):
        self.simulate(isodd)

def setchunksize(size:int):
    """set chunk size. Must be called when no chunk is defined, and before defining any or expect weird crashs"""
    global chunksize,cchunksize
    if size>=2:
        chunksize=size
        cchunksize=size
    else:
        raise ValueError("chunk size must be at least 2")