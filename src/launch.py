#!/usr/bin/env python3
# encoding=utf8

# Fichier utilisé pour lancer le code "a la main (sans installer la wheel)"

#using config file in local dir
from sys import argv
if "--config-file" not in argv:
    import os
    path=os.path.join(os.path.abspath(os.path.dirname(__file__)),"settings.json")
    argv.append("--config-file")
    argv.append(path)

import Coralien
Coralien.launch_app()
