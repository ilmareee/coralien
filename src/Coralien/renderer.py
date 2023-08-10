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
        print("Numpy is a required depandancy, please install it")
    sys.exit(1)
try:
    from PIL import Image
except:
    if settings["logging"]>=1:
        print("PIL is a required depandancy, please install it")
    sys.exit(1)

from . import cy_sim



_generation:int=0

transformer:QTransform=QTransform()
class Renderer(QWidget):
    def paintEvent(self, event: QPaintEvent) -> None:
        """event triggered by self.repaint, which displays the new image"""
        painter=QPainter(self)
        painter.translate(self.rect().center())
        painter.setTransform(transformer,combine=True)
        for pos,chunk in cy_sim.chunks.items():
            x,y=pos
            x*=cy_sim.chunksize
            y*=cy_sim.chunksize
            painter.drawPixmap(x,y,chunk.getimg(_generation%2))
renderer=QWidget()
_renderer=Renderer()
_renderer.setSizePolicy(QSizePolicy.Policy.Expanding,QSizePolicy.Policy.Expanding)
renderer.setLayout(QVBoxLayout())
_genlabel=QLabel("generation: 0")
renderer.layout().addWidget(_genlabel)
renderer.layout().addWidget(_renderer)


def nextgen(*_,generations:int=1) -> None:
    """process the simulation of one or many generations, and then display the new grid"""
    for i in range(generations):
        global _generation
        cy_sim.simulate(_generation%2)
        _generation+=1
    _renderer.repaint()
    _genlabel.setText(f"generation: {_generation}")

def reinitrenderer() -> None:
    """reinitializes the grid, zoom and placement"""
    global _generation,transformer
    _generation = 0
    transformer=QTransform(2,0,0,
                           0,2,0,
                           0,0,1)
    _genlabel.setText("generation: 0")
    _renderer.repaint()

