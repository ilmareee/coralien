# Coralien

Comme son nom l'indique, ceci est un projet de coralien.
Écrit essentiellement en python, il intègre une bonne partie de cython pour des raisons de performance, aussi recherchées par l'appel au multithreading.

Les librairies utilisées sont :
 - Openmp : pour le multithreading
 - PySide6 : pour le GUI.
 - Pillow : Pour obtenir le rendu de la grille de jeu.
 - setuptools et setuptools\_scm : pour le build des wheels et du cython.
 - numpy : pour avoir des tableaux rapide d'accès.
 - cython : pour la possibilité de compiler en C afin de rendre l'exécution plus rapide.

## Principe de fonctionement :
Ce coralien gère les cellules par chunks de taille configurable (16\*16 par défaut), ainsi, les chunks inactifs (c.à.d ceux constitués de cellules vides ou mortes) ne sont ni simulés ni représentés.
Les règles sont les suivantes : une cellule vide (noire) devient vivante (rouge) si au moins trois de ses voisines sont vivantes et moins de 5 sont mortes (cyan). Une cellule vivante meure si elle est entourée d'au moins 5 cellules vivantes, 5 cellules mortes ou de moins de 2 cellules vivantes. Ces règles sont hardcodées dans lib/cy\_sim.pyx et ne sont pas paramétrables.
On peut zoomer l'image rendue avec le scroll de la souris, ainsi que déplacer celle-ci avec les touches z,q,s,d.

## Instructions de build :
Le programme est compilé et build en utilisant la commande `python3 setup.py build_ext` pour une utilisation locale
Avec la commande précédente, on lance le programme en exécutant le fichier `src/launch.py`
On peut également le build en tant que wheel installée, auquel cas on la lance par la commande `Coralien`

## Licence :
Ce projet est licencié avec "The Unlicense" : Faites ce que vous voulez du programme, sans aucune garantie. Pour plus de détails, lisez le fichier LICENSE (en anglais).

