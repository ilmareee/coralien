# cython: nonecheck=False
# cython: language_level=3str

# distutils: language = c++

from re import T
from PySide6.QtGui import QPixmap
from cython.operator import dereference
import numpy as np
cimport numpy as cnp
cimport cython
from cpython cimport PyObject
from cython.parallel import prange
from PIL import Image
from PIL.ImagePalette import ImagePalette
from PIL.ImageQt import ImageQt
from libcpp.vector cimport vector



cnp.import_array()
DTYPE = np.int8
ctypedef cnp.int8_t DTYPE_t

_palarr:list[int]=[0,0,0,     #RGB color palette: empty, alive then dead 
                   255,0,0,
                   0,255,255]

palette=ImagePalette(mode='RGB',palette=_palarr)

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

cdef cells_view new_cells_view(DTYPE_t center,DTYPE_t up,DTYPE_t left,DTYPE_t down,DTYPE_t right,DTYPE_t upleft,DTYPE_t downleft,DTYPE_t downright,DTYPE_t upright) nogil:
    cdef cells_view view
    view.center=center
    view.up=up
    view.left=left
    view.down=down
    view.right=right
    view.upleft=upleft
    view.downleft=downleft
    view.downright=downright
    view.upright=upright

    return view

@cython.boundscheck(False) # turn off bounds-checking for entire function
@cython.wraparound(False)  # turn off negative index wrapping for entire function
cdef DTYPE_t simulate_one(cells_view cells) nogil:
    if cells.center==2: #cell is dead
        return 2
    
    cdef short alives=0
    cdef short deads=0
    cdef short x
    cdef DTYPE_t[8] arr = (cells.down,cells.downleft,cells.downright,cells.left,cells.right,cells.up,cells.upleft,cells.upright)
    for x in range(8):
        if arr[x]==2:
            deads+=1
        elif arr[x]==1:
            alives+=1

    if cells.center==0: # cell is empty
        if alives==3 and deads<=5:
            return 1
        else:
            return 0
    else: #cell is alive
        if alives>5 or alives<2 or deads>5:
            return 2
        else:
            return 1

chunksize:int=2
cdef short cchunksize=2
cdef DTYPE_t[:,:] zeros_arr=np.zeros((2,2),dtype=DTYPE)
cdef DTYPE_t[:] zeros_arr_corner=np.zeros((2),dtype=DTYPE)


cdef class chunk:
    cdef cnp.ndarray nparray
    cdef DTYPE_t[:,:,:] memview

    cdef DTYPE_t[:,:] up
    cdef DTYPE_t[:,:] left
    cdef DTYPE_t[:,:] right
    cdef DTYPE_t[:,:] down
    cdef DTYPE_t[:] upleft
    cdef DTYPE_t[:] upright
    cdef DTYPE_t[:] downleft
    cdef DTYPE_t[:] downright
    cdef bint active
    posx:cython.py_int
    posy:cython.py_int
    cached_pixmap:QPixmap

    def __init__(self,posx:int,posy:int,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None,startarr:np.array=None) -> None:

        if startarr is None:
            self.nparray=np.zeros((chunksize,chunksize,2),dtype=DTYPE)
        else:
            self.nparray=startarr
        self.memview=self.nparray

        self.posx=posx
        self.posy=posy

        self.up=zeros_arr
        self.down=zeros_arr
        self.right=zeros_arr
        self.left=zeros_arr
        self.upleft=zeros_arr_corner
        self.upright=zeros_arr_corner
        self.downleft=zeros_arr_corner
        self.downright=zeros_arr_corner
        self.add_voisins(up,down,right,left,upleft,upright,downleft,downright)
        self.active = True

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    def add_voisins(self,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None,upleft:chunk=None,upright:chunk=None,downleft:chunk=None,downright:chunk=None) -> None:
        if up is not None:
            self.up=up.memview[:,-1,:]
        if down is not None:
            self.down=down.memview[:,0,:]
        if right is not None:
            self.right=right.memview[0,:,:]
        if left is not None:
            self.left=left.memview[-1,:,:]
        if upleft is not None:
            self.upleft=upleft.memview[-1,-1,:]
        if upright is not None:
            self.upright=upright.memview[0,-1,:]
        if downleft is not None:
            self.downleft=downleft.memview[-1,0,:]
        if downright is not None:
            self.downright=downright.memview[0,0,:]
        self.active = True
 
    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    cdef void simulate(self,isodd:short) nogil:
        #on ODD: [:,:,1]->[:,:,0], reverse on non ODD
        #return true if at least one cell is alive
        if not self.active:
            return
        self.active=False

        cdef short x,y
        cdef DTYPE_t newv
        cdef cells_view cells
        for x in range(cchunksize):
            for y in range(cchunksize):
                if x!=0 and x!=cchunksize-1:
                    if y!=0 and y!=cchunksize-1:
                        cells=new_cells_view( #mid
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            self.active=True
                    elif y==0:
                        cells=new_cells_view( # up
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target:chunk=chunks.get((self.posx, self.posy-1))
                                if target==None :
                                    new_chunk(self.posx, self.posy-1)
                                else :
                                    target.active=True
                            self.active=True

                    else:
                        cells=new_cells_view( # low
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target:chunk=chunks.get((self.posx, self.posy+1))
                                if target==None:
                                    new_chunk(self.posx, self.posy+1)
                                else:
                                    target.active=True
                            self.active=True
                elif x==0:
                    if y!=0 and y!=cchunksize-1:
                        cells=new_cells_view( # lef
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target:chunk=chunks.get((self.posx-1, self.posy))
                                if target==None:
                                    new_chunk(self.posx-1, self.posy)
                                else:
                                    target.active=True
                            self.active=True
                    elif y==0:
                        cells=new_cells_view( # uplef
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target=chunks.get((self.posx-1, self.posy-1))
                                if target==None:
                                    new_chunk(self.posx-1, self.posy-1)
                                else:
                                    target.active=True
                                target=chunks.get((self.posx, self.posy-1))
                                if target!=None:
                                    target.active=True
                                target=chunks.get((self.posx-1, self.posy))
                                if target!=None:
                                    target.active=True
                            self.active=True

                    else:
                        cells=new_cells_view( # lowl
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target=chunks.get((self.posx-1, self.posy+1))
                                if target==None:
                                    new_chunk(self.posx-1, self.posy+1)
                                else:
                                    target.active=True
                                target=chunks.get((self.posx, self.posy+1))
                                if target!=None:
                                    target.active=True
                                target=chunks.get((self.posx-1, self.posy))
                                if target!=None:
                                    target.active=True
                            self.active=True
                else:
                    if y!=0 and y!=cchunksize-1:
                        cells=new_cells_view( # r
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target=chunks.get((self.posx+1, self.posy))
                                if target==None:
                                    new_chunk(self.posx+1, self.posy)
                                else:
                                    target.active=True
                            self.active=True
                    elif y==0:
                        cells=new_cells_view( #upr
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target=chunks.get((self.posx+1, self.posy-1))
                                if target==None:
                                    new_chunk(self.posx+1, self.posy-1)
                                else:
                                    target.active=True
                                target=chunks.get((self.posx, self.posy-1))
                                if target!=None:
                                    target.active=True
                                target=chunks.get((self.posx+1, self.posy))
                                if target!=None:
                                    target.active=True
                            self.active=True
                    else:
                        cells=new_cells_view( # lowr
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
                        newval=simulate_one(cells)
                        self.memview[x,y,1-isodd] = newval
                        if newval!=cells.center:
                            with gil:
                                target=chunks.get((self.posx+1, self.posy+1) )
                                if target==None:
                                    new_chunk(self.posx+1, self.posy+1)
                                else:
                                    target.active=True
                                target=chunks.get((self.posx, self.posy+1))
                                if target!=None:
                                    target.active=True
                                target=chunks.get((self.posx+1, self.posy))
                                if target!=None:
                                    target.active=True
                            self.active=True


    def getimg(self,isodd:int) -> QPixmap:
        if not self.active:
            return self.cached_pixmap
        img=Image.fromarray(self.nparray[:,:,isodd].T,mode='P')
        img.putpalette(palette)
        qtimg=QPixmap(ImageQt(img))
        self.cached_pixmap=qtimg
        return qtimg


def setchunksize(size:int):
    """set chunk size. Must be called when no chunk is defined, and before defining any or expect weird crashs"""
    global chunksize,cchunksize,zeros_arr
    if size>=2:
        chunksize=size
        cchunksize=size
        zeros_arr=np.zeros((size,size),dtype=DTYPE)
    else:
        raise ValueError("chunk size must be at least 2")




chunks:dict[tuple[int,int],chunk]={}
ctypedef PyObject *PyObjptr
cdef vector[PyObjptr] *chunkvector

cdef void new_chunk(x:int,y:int,isodd:short=0,cnp.ndarray start=None):
    global chunks
    up:chunk=chunks[(x,y-1)] if (x,y-1) in chunks else None
    down:chunk=chunks[(x,y+1)] if (x,y+1) in chunks else None
    left:chunk=chunks[(x-1,y)] if (x-1,y) in chunks else None
    right:chunk=chunks[(x+1,y)] if (x+1,y) in chunks else None
    upleft:chunk=chunks[(x-1,y-1)] if (x-1,y-1) in chunks else None
    upright:chunk=chunks[(x+1,y-1)] if (x+1,y-1) in chunks else None
    downleft:chunk=chunks[(x-1,y+1)] if (x-1,y+1) in chunks else None
    downright:chunk=chunks[(x+1,y+1)] if (x+1,y+1) in chunks else None

    arr:np.array=None

    if start is not None:
        arr=np.zeros((chunksize,chunksize,2),DTYPE)
        arr[:,:,isodd]=start

    newch=chunk(x,y,up,down,right,left,upleft,upright,downleft,downright,arr)
    newch.getimg(isodd)
    chunks[(x,y)]=newch
    chunkvector.push_back(<PyObjptr>newch)

    if up is not None:
        up.add_voisins(down=newch)
    if down is not None:
        down.add_voisins(up=newch)
    if left is not None:
        left.add_voisins(right=newch)
    if right is not None:
        right.add_voisins(left=newch)
    if upleft is not None:
        upleft.add_voisins(downright=newch)
    if upright is not None:
        upright.add_voisins(downleft=newch)
    if downleft is not None:
        downleft.add_voisins(upright=newch)
    if downright is not None:
        downright.add_voisins(upleft=newch)

def start(arr:np.ndarray) -> None:
    """reinit and start a new simulation with given start situation
    start situation must be of a size multiple of chunksize (or border will be avoided)"""
    global chunks,chunkvector
    chunks={}
    chunkvector=new vector[PyObjptr](0)
    print(chunkvector.size())
    new_chunk(-1,-1)
    for i in range(arr.shape[0]//chunksize):
        new_chunk(i,-1)
        for j in range(arr.shape[1]//chunksize):
            new_chunk(i,j,False,arr[i*chunksize:(i+1)*chunksize,j*chunksize:(j+1)*chunksize])
        new_chunk(i,j+1)
    for j in range(arr.shape[1]//chunksize):
        new_chunk(-1,j)
        new_chunk(i+1,j)
    new_chunk(i+1,-1)
    new_chunk(-1,j+1)
    new_chunk(i+1,j+1)
    print(chunkvector.size())
def simulate(isodd:int) -> None:
    cdef short cisodd=isodd
    cdef int i
    cdef size_t lenght=chunkvector.size()
    for i in prange(0,lenght,nogil=True,schedule='guided'):
        with gil:
            select:chunk=<object>dereference(chunkvector)[i]
        select.simulate(cisodd)
    