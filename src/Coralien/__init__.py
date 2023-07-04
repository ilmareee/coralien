# encoding=utf8

import sys
import os
from typing import NoReturn

# parsing de certaines options passées à l'appel
if "--licence" in sys.argv:
    with open("LICENSE", encoding="utf-8") as license:
        print(license.read())
        exit(0)
if "--help" in sys.argv or "-h" in sys.argv:
    print("""Coralien [OPTIONS]

    OPTIONS:
        --help   -h         Show this help
        --license           Show the license
        --no-settings       Use only default settings
        --config-file PATH  PATH to use for the configuration file
    
    all non recognised option are ignored
    all option are passed to PySide, so PySide (QT) option should work to
    """)
    exit(0)

from .settings import settings

if settings["logging"]>=2:
    print("Invocation :",sys.argv)
    print("program directory",os.path.abspath(os.path.dirname(__file__)))



def launch_app() -> NoReturn:
    if settings["logging"]>=3:
        print("Attempting to import the main program")
    from . import main
    if settings["logging"]>=3:
        print("No error, proceding to launch the QT app")
    sys.exit(main.app.exec_())