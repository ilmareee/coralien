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
        print("\nle module PySide6 devrait être installé pour que ce programme puisse fonctionner, lisez README.md pour plus de détails", file=sys.stderr)
    raise e


#main Qt loop
app: QApplication = QApplication(sys.argv)
from . import rendu
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


###Main windows configuration
#yes, there will be only one instance of this windows, but the class is nescessary to ovverride some method (such as closeEvent)
class Main_window(QWidget):
    #Main windows class
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
        
        for name,function in (("next",rendu.nextgen),("next*10",partial(rendu.nextgen,generation=10))):
            self.button.append(QPushButton(name))
            self.button[-1].clicked.connect(function)
            self._cbarl.addWidget(self.button[-1])
        
        
        self.layout().addWidget(self._controlbar)
        self.layout().addWidget(rendu.rendu)
        
        if settings["logging"]>=3:
            print("initializing main windows complete")


MainWin:QWidget=Main_window()
MainWin.show()

#setting up the simulation
try:
    from . import cy_sim
except ImportError as e:
    print("You must compile the cy_sim module in order to use the Coralien app. Please see README.md for details")
    raise(e)

cy_sim.setchunksize(settings["sim.chunk_size"])
cy_sim.start(np.random.randint(0,3,(settings["sim.chunk_size"],settings["sim.chunk_size"]),dtype=np.int8))