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
cdef DTYPE_t simulate_one(DTYPE_t[:,:,:] cells,cython.bool isodd) nogil:
    """cells should be a 3*3*2 memoryview, return True if cur state != next state"""

    if cells[1,1,isodd]==-1:
        cells[1,1,1-isodd]=-1
        return False
            
    
    cdef short alives,deads,x,y
    for x in range(3):
        for y in range(3):
            if x!=1 or y!=1:
                if cells[x,y,isodd]==1:
                    alives+=1
                elif cells[x,y,isodd]==-1:
                    deads+=1
    if cells[1,1,isodd]==0: # cell is empty
        if alives==3 and deads<=3:
            cells[1,1,1-isodd]=1
            return True
        else:
            return False
    else: #cell is alive
        if alives>3 or alives<2 or deads>3:
            cells[1,1,1-isodd]=-1
            return True
        else:
            cells[1,1,1-isodd]=1
            return False

chunksize:int=2
cdef short cchunksize=2

cdef class chunk:
    cdef DTYPE_t[:,:,:] memview
    def __init__(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:

        cdef cnp.ndarray nparray=np.zeros((chunksize,chunksize,2),dtype=DTYPE)
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

        cdef short x,y,looprange
        looprange=cchunksize+1
        for x in range(1,looprange):
            for y in range(1,looprange):
                simulate_one(self.memview[x-1:x+1,y-1:y+1,:],isodd)

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