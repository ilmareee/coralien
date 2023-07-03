import sys
from . import settings

try:
    from PySide6.QtCore import *
    from PySide6.QtWidgets import *
    from PySide6.QtGui import *
except ModuleNotFoundError as e:
    if settings.get("logging")>=1:
        print(e,"\nle module PySide6 devrait être installé pour que ce programme puisse fonctionner, lisez README.md pour plus de détails", file=sys.stderr)
    sys.exit(1)
    

app: QApplication = QApplication(sys.argv)

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

MainWin:QWidget=QWidget()
MainWin.setFocusPolicy(Qt.ClickFocus)




MainWin.show()