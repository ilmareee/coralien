# cython: infer_types=True
import numpy as np
cimport numpy as cnp
cimport cython


cnp.import_array()
DTYPE = np.int16
ctypedef cnp.int16_t DTYPE_t


@cython.boundscheck(False) # turn off bounds-checking for entire function
@cython.wraparound(False)  # turn off negative index wrapping for entire function
cdef bint simulate_one(DTYPE_t[:,:] cells) nogil:
    #cells should be a 3*3 memoryview, may change center value, return True if, (and only if) center value changed
    return False


class chunk():
    def __init__(self,size:int,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None) -> None:

        outersize:int=size+2
        cdef cnp.ndarray nparray=np.zeros((outersize,outersize,2),dtype=np.short)
        self.nparray=nparray
        cdef int[:,:,:] memview = self.nparray
        self.memview=memview

        self.up=up
        self.down=down
        self.right=right
        self.left=left
        cdef int csize=size
        self.size=csize
    def add_voisins(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None) -> None:
        if up!=None:
            self.up=up
        if down!=None:
            self.down=down
        if right!=None:
            self.right=right
        if left!=None:
            self.left=left
    
    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    cdef simulate(self,isodd:bint) nogil:
        #on ODD: [:,:,1]->[:,:,0], reverse on non ODD
        cdef short source,dest
        if isodd:
            source=1
            dest=0
        else:
            source=0
            dest=1

        cdef short x,y,looprange
        looprange=self.size+1
        for x in range(1,looprange):
            for y in range(1,looprange):
                simulate_one(self.memview[x-1:x+1,y-1:y+1,source])

    def py_direct_simulate(self,isodd:bool):
        self.simulate(isodd)