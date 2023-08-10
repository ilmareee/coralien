from functools import partial
import sys

import numpy as np

from . import settings
from .settings import settings

try:
    from PySide6.QtCore import *
    from PySide6.QtWidgets import *
    from PySide6.QtGui import *
except ModuleNotFoundError as e:
    if settings["logging"]>=1:
        print("\nthe PySide6 module must be installed in order for this program to execute, please read the README for further details", file=sys.stderr)
    raise e


try:
    from . import cy_sim
except ImportError as e:
    print("You must compile the cy_sim module in order to use the Coralien app. Please read the README for further details")
    raise(e)

#main Qt loop
app: QApplication = QApplication(sys.argv)
from . import renderer
###genral utilities windows and functions 
__warnwin = QScrollArea()
__warnwintxt = QLabel(__warnwin)
__warnwin.setWidget(__warnwintxt)
__warnwin.setWindowTitle("WARNINGS:")

def warn(warning:str,gravity:int)->None:
    if settings.get("logging")>=gravity:
        if settings.get("affichage.warn"):
            __warnwintxt.setText(__warnwintxt.text() + "\n\n" + warning)
            __warnwin.show()
        else:
            print(warning)

#setting up or reinitializing the simulation
def reinit() -> None:
    cy_sim.start(np.random.randint(0,2,(settings["sim.chunk_size"],settings["sim.chunk_size"]),dtype=np.int8))
    renderer.reinitrenderer()

cy_sim.setchunksize(settings["sim.chunk_size"])
reinit()

###Main window configuration
#there will be only one instance of this windows, but the class is nescessary to ovverride some method (such as closeEvent)
class Main_window(QWidget):
    #Main window class
    def __init__(self) -> None:
        super().__init__()
        if settings["logging"]>=3:
            print("initializing main windows")
        
        self.setFocusPolicy(Qt.ClickFocus)
        self.setWindowTitle("Coralien")
        self.setLayout(QVBoxLayout())
        self._controlbar=QWidget()
        
        self.button:list[QAbstractButton]=[]
        self._cbarl=QHBoxLayout()
        self._controlbar.setLayout(self._cbarl)
        
        self.timer: QTimer = QTimer(self)
        
        #buttons which will be displayed on the window
        for name,function in (("next",renderer.nextgen),("next*10",partial(renderer.nextgen,generations=10)),
                              ("start automatic simulation",self.timer.start),("stop autosim", self.timer.stop),("reinitialize simulation", reinit)):
            self.button.append(QPushButton(name))
            self.button[-1].clicked.connect(function)
            self._cbarl.addWidget(self.button[-1])
        
        
        self.layout().addWidget(self._controlbar)
        self.layout().addWidget(renderer.renderer)
        
        self.timer.setInterval(1/settings["sim.fps"]*1000)
        self.timer.timeout.connect(renderer.nextgen)
        
        #key controls of the image
        self.contsens=settings["affichage.controles.sensibilite"]
        self.controles: dict[str, list[QKeySequence]]={
            "droite":    [QKeySequence(i) for i in settings["affichage.controles.droite"]],
            "gauche":    [QKeySequence(i) for i in settings["affichage.controles.gauche"]],
            "monter":    [QKeySequence(i) for i in settings["affichage.controles.monter"]],
            "descendre":    [QKeySequence(i) for i in settings["affichage.controles.descendre"]],
        }
        
        
        if settings["logging"]>=3:
            print("initializing main windows complete")
    
    def keyPressEvent(self, event) -> None:
        """ Moves the displayed image.

        Args:
            event (class 'PySide6.QtGui.QKeyEvent'): pressed key.
        """
         
        if event.keyCombination().toCombined() in self.controles["droite"]:
            renderer.transformer.translate(-self.contsens,0)
        if event.keyCombination().toCombined() in self.controles["gauche"]:
            renderer.transformer.translate(self.contsens,0)
        if event.keyCombination().toCombined() in self.controles["monter"]:
            renderer.transformer.translate(0,self.contsens)
        if event.keyCombination().toCombined() in self.controles["descendre"]:
            renderer.transformer.translate(0,-self.contsens)
        renderer._renderer.repaint()
        
    def wheelEvent(self, event):
        """Used to zoom in or out.

        Args:
            event (class 'PySide6.QtGui.QWheelEvent'): mouse scroll.
        """
        y=event.angleDelta().y()
        if y > 100:
            scale=1+self.contsens/100
            
        elif y<-100:
            scale=1/(1+self.contsens/100)
        elif y>0:
            scale=1+y/1000*self.contsens
        else:
            scale=1/(1-y/1000*self.contsens)
        renderer.transformer.scale(scale,scale)
        renderer._renderer.repaint()

MainWin:QWidget=Main_window()
MainWin.show()

