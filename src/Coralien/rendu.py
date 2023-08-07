import sys
from PySide6.QtCore import *
from PySide6.QtWidgets import *
from PySide6.QtGui import *

from .settings import settings

try:
    import numpy as np
except:
    if settings["logging"]>=1:
        print("Numpy is a required depandancie, please install it")
    sys.exit(1)
try:
    from PIL import Image
except:
    if settings["logging"]>=1:
        print("PIL is a required depandancie, please install it")
    sys.exit(1)

from . import cy_sim

cy_sim.setchunksize(settings["sim.chunk_size"])

class ZoneDeRendu(QWidget):
    def __init__(self):
        super().__init__()
        self.generation:int=0
        self.setLayout(QGridLayout())
    def nextgen(self,generations:int=1):
        self.generation+=generations
    
    def redraw(self):
        pass