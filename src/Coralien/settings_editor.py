from . import settings
from PySide6.QtCore import *
from PySide6.QtWidgets import *
from PySide6.QtGui import *


class settings_editor(QWidget):
    def __init__(self):
        super().__init__()
        self.lay=QGridLayout()
        self.setLayout(self.lay)
        
        
        