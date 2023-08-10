import sys
from PySide6.QtCore import *
import PySide6.QtGui
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



_generation:int=0

transformer:QTransform=QTransform()
class Renderer(QWidget):
    def paintEvent(self, event: QPaintEvent) -> None:
        painter=QPainter(self)
        painter.translate(self.rect().center())
        painter.setTransform(transformer,combine=True)
        for pos,chunk in cy_sim.chunks.items():
            x,y=pos
            x*=cy_sim.chunksize
            y*=cy_sim.chunksize
            painter.drawPixmap(x,y,chunk.getimg(_generation%2))
rendu=QWidget()
_renderer=Renderer()
_renderer.setSizePolicy(QSizePolicy.Policy.Expanding,QSizePolicy.Policy.Expanding)
rendu.setLayout(QVBoxLayout())
_genlabel=QLabel("generation: 0")
rendu.layout().addWidget(_genlabel)
rendu.layout().addWidget(_renderer)


def nextgen(*_,generations:int=1) -> None:
    for i in range(generations):
        global _generation
        cy_sim.simulate(_generation%2)
        _generation+=1
    _renderer.repaint()
    _genlabel.setText(f"generation: {_generation}")

def reinitrendu() -> None:
    global _generation,transformer
    _generation = 0
    transformer=QTransform(2,0,0,
                           0,2,0,
                           0,0,1)
    _genlabel.setText("generation: 0")
    _renderer.repaint()
    
