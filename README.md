# Coralien

Comme son nom l'indique, ceci est un projet de coralien.
Écrit essentiellement en python, il intégrera peut-être du cython par la suite pour des raisons de performance.

Les librairies utilisées sont :
 - PySide6 : pour le GUI.
 - Pillow : Pour obtenir le rendu de la grille de jeu.
 - setuptools et setuptools_scm : pour le build des wheels et du cython.
 - numpy : pour avoir des tableaux rapide d'accès.
 - cython : pour la possibilité de compiler en C afin de rendre l'exécution plus rapide.

## Principe de fonctionement :
Ce coralien gère les cellules par chunks de taille configurable, ainsi, les chunks inactifs (c.à.d ceux constitués de cellules vides ou mortes) ne sont ni simulés ni représentées (enfin c'est l'objectif...).

## Licence :
Ce projet est licencié avec "The Unlicense" : Faites ce que vous voulez du programme, sans aucune garantie. Pour plus de détails, lisez le fichier LICENSE (en anglais).
