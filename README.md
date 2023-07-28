# Coralien

Comme son nom l'indique, ceci est un projet de coralien.
Écrit essentiellement en python, il intégrera peut-être du cython par la suite pour des raisons de performance.

Les librairies utilisées sont :
 - PySide6 : pour le GUI.
 - setuptools et setuptools_scm : pour le build des wheels et du cython.
 - cython : pour la possibilité de compiler en C afin de rendre l'execution plus rapide.

## Principe de fonctionement
Ce coralien gère les cellules par chunks de taile cobnfigurable, ainsi, les chunks inactifs (c.à.d ou toutes les cellules sont vides ou mortes) ne sont pas simulé et re rendu
(enfin c'est l'objectif ....)

## Licence:
Ce projet est licencié avec "The Unlicense" : Faites ce que vous voulez du programme, sans aucune garantie. Pour plus de détails, lisez le fichier LICENSE (en anglais).
