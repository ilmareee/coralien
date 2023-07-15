# cython: infer_types=True
import numpy as np

class chunk():
    def __init__(self,size:int,up:chunk=None,down:chunk=None,right:chunk=None,left:chunk=None) -> None:
        outersize=size+2
        self.nparray=np.zeros((outersize,outersize,2),dtype=np.int16_t)
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
    def simulate(self,isodd:bool):
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
                pass
