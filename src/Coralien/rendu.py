import sys
from PySide6.QtCore import *
from PySide6.QtWidgets import *
from PySide6.QtGui import *

from .settings import settings

try:
    import numpy as np
except:
    if settings["logging"]>=1:
        print("Numpy is a required depandancie, plesa install it")
    sys.exit(1)

class ZoneDeRendu(QWidget):
    pass