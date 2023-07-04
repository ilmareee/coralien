import sys
from typing import Optional

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
        
        if settings["logging"]>=3:
            print("initializing main windows complete")


MainWin:QWidget=Main_window()
MainWin.show()