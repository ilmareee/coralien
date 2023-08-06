# cython: nonecheck=False
# cython: language_level=3str
import numpy as np
cimport numpy as cnp
cimport cython


cnp.import_array()
DTYPE = np.int16
ctypedef cnp.int16_t DTYPE_t

ctypedef struct cells_view :
    DTYPE_t center
    DTYPE_t up
    DTYPE_t left
    DTYPE_t down
    DTYPE_t right
    DTYPE_t upleft
    DTYPE_t downleft
    DTYPE_t downright
    DTYPE_t upright


@cython.boundscheck(False) # turn off bounds-checking for entire function
@cython.wraparound(False)  # turn off negative index wrapping for entire function
cdef DTYPE_t simulate_one(cells_view cells) nogil:
    if cells.center==-1:
        return -1
    
    cdef short alives,deads
    cdef DTYPE_t x
    for x in [cells.up, cells.left, cells.down, cells.right, cells.upleft, cells.downleft, cells.downright, cells.upright]:
        if x==1:
            alives+=1
        elif x==-1:
            deads+=1
    if cells.center==0: # cell is empty
        if alives==3 and deads<=3:
            return 1
        else:
            return 0
    else: #cell is alive
        if alives>3 or alives<2 or deads>3:
            return -1
        else:
            return 1

chunksize:int=2
cdef short cchunksize=2
cdef DTYPE_t[:,:] zeros_arr=np.zeros((2,2),dtype=DTYPE)
cdef DTYPE_t[:] zeros_arr_corner=np.zeros((2),dtype=DTYPE)


cdef class chunk:
    cdef public cnp.ndarray nparray
    cdef DTYPE_t[:,:,:] memview

    cdef DTYPE_t[:,:] up
    cdef DTYPE_t[:,:] left
    cdef DTYPE_t[:,:] right
    cdef DTYPE_t[:,:] down
    cdef DTYPE_t[:] upleft
    cdef DTYPE_t[:] upright
    cdef DTYPE_t[:] downleft
    cdef DTYPE_t[:] downright

    def __init__(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:

        cdef cnp.ndarray nparray=np.zeros((chunksize,chunksize,2),dtype=DTYPE)
        self.nparray=nparray
        self.memview=self.nparray

        self.up=zeros_arr
        self.down=zeros_arr
        self.right=zeros_arr
        self.left=zeros_arr
        self.upleft=zeros_arr_corner
        self.upright=zeros_arr_corner
        self.downleft=zeros_arr_corner
        self.downright=zeros_arr_corner
        self.add_voisins(up,down,right,left,upleft,upright,downleft,downright)

    def add_voisins(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:
        if up!=None:
            self.up=up.memview[:,-1,:]
        if down!=None:
            self.down=down.memview[:,0,:]
        if right!=None:
            self.right=right.memview[0,:,:]
        if left!=None:
            self.left=left.memview[-1,:,:]
        if upleft!=None:
            self.upleft=upleft.memview[-1,-1,:]
        if upright!=None:
            self.upright=upright.memview[0,-1,:]
        if downleft!=None:
            self.downleft=downleft.memview[-1,0,:]
        if downright!=None:
            self.downright=downright.memview[0,0,:]
 
    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    cdef bint simulate(self,isodd:cython.bint) nogil:
        #on ODD: [:,:,1]->[:,:,0], reverse on non ODD
        #return true if at least one cell is alive

        cdef short x,y
        cdef DTYPE_t newv
        cdef cells_view cells
        for x in range(cchunksize):
            for y in range(cchunksize):
                if x!=0 and x!=cchunksize-1:
                    if y!=0 and y!=cchunksize-1:
                        cells=cells_view(
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.memview[x-1,y,isodd],
                                self.memview[x,y+1,isodd],
                                self.memview[x+1,y,isodd],
                                self.memview[x-1,y-1,isodd],
                                self.memview[x-1,y+1,isodd],
                                self.memview[x+1,y+1,isodd],
                                self.memview[x+1,y-1,isodd]
                                )
                    elif y==0:
                        cells=cells_view( #y = 0
                                self.memview[x,y,isodd],
                                self.up[x,isodd],
                                self.memview[x-1,y,isodd],
                                self.memview[x,y+1,isodd],
                                self.memview[x+1,y,isodd],
                                self.up[x-1,isodd],
                                self.memview[x-1,y+1,isodd],
                                self.memview[x+1,y+1,isodd],
                                self.up[x+1,isodd]
                                )
                    else:
                        cells=cells_view( # y = cchunksize
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.memview[x-1,y,isodd],
                                self.down[x,isodd],
                                self.memview[x+1,y,isodd],
                                self.memview[x-1,y-1,isodd],
                                self.down[x-1,isodd],
                                self.down[x+1,isodd],
                                self.memview[x+1,y-1,isodd]
                                )
                elif x==0:
                    if y!=0 and y!=cchunksize-1:
                        cells=cells_view( # x = 0
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.left[y,isodd],
                                self.memview[x,y+1,isodd],
                                self.memview[x+1,y,isodd],
                                self.left[y-1,isodd],
                                self.left[y+1,isodd],
                                self.memview[x+1,y+1,isodd],
                                self.memview[x+1,y-1,isodd]
                                )
                    elif y==0:
                        cells=cells_view( #y = 0
                                self.memview[x,y,isodd],
                                self.up[x,isodd],
                                self.left[y,isodd],
                                self.memview[x,y+1,isodd],
                                self.memview[x+1,y,isodd],
                                self.upleft[isodd],
                                self.left[y+1,isodd],
                                self.memview[x+1,y+1,isodd],
                                self.up[x+1,isodd]
                                )
                    else:
                        cells=cells_view( # y = cchunksize
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.left[y,isodd],
                                self.down[x,isodd],
                                self.memview[x+1,y,isodd],
                                self.left[y-1,isodd],
                                self.downleft[isodd],
                                self.down[x+1,isodd],
                                self.memview[x+1,y-1,isodd]
                                )
                else:
                    if y!=0 and y!=cchunksize-1:
                        cells=cells_view( # x = cchunksize
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.memview[x-1,y,isodd],
                                self.memview[x,y+1,isodd],
                                self.right[y,isodd],
                                self.memview[x-1,y-1,isodd],
                                self.memview[x-1,y+1,isodd],
                                self.right[y+1,isodd],
                                self.right[y-1,isodd]
                                )
                    elif y==0:
                        cells=cells_view( #y = 0
                                self.memview[x,y,isodd],
                                self.up[x,isodd],
                                self.memview[x-1,y,isodd],
                                self.memview[x,y+1,isodd],
                                self.right[y,isodd],
                                self.up[x-1,isodd],
                                self.memview[x-1,y+1,isodd],
                                self.right[y+1,isodd],
                                self.upright[isodd]
                                )
                    else:
                        cells=cells_view( # y = cchunksize
                                self.memview[x,y,isodd],
                                self.memview[x,y-1,isodd],
                                self.memview[x-1,y,isodd],
                                self.down[x,isodd],
                                self.right[y,isodd],
                                self.memview[x-1,y-1,isodd],
                                self.down[x-1,isodd],
                                self.downright[isodd],
                                self.right[y-1,isodd]
                                )
                self.memview[x,y,1-isodd] = simulate_one(cells)

    def py_direct_simulate(self,isodd:bool):
        self.simulate(isodd)

def setchunksize(size:int):
    """set chunk size. Must be called when no chunk is defined, and before defining any or expect weird crashs"""
    global chunksize,cchunksize,zeros_arr
    if size>=2:
        chunksize=size
        cchunksize=size
        zeros_arr=np.zeros((size,size),dtype=DTYPE)
    else:
        raise ValueError("chunk size must be at least 2")
