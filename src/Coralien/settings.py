#  Code sous liscence GPL3+. Plus de détail a <https://www.gnu.org/licenses/> ou dans le fichier LICENCE
# encoding = utf8
import json
from operator import delitem
import os
from typing import Any
from sys import stderr, argv
from typing_extensions import override


class settings_collection():
    def __init__(self,dictionary:dict={}) -> None:
        self._dict:dict=dictionary
    
    def __getitem__(self, __key: str) -> Any:
        if __debug__:
            if not isinstance(__key,str):
                raise NotImplementedError("cant access settings collection with something else than a string")
        keys: list[str]=__key.split('.')
        cursor: dict=self._dict
        for key in keys:
            cursor=cursor[key]
        return cursor
    
    def __setitem__(self,__key,value) -> None:
        if __debug__:
            if not isinstance(__key,str):
                raise NotImplementedError("cant access settings collection with something else than a string")
        keys: list[str]=__key.split('.')
        cursor: dict=self._dict
        for key in keys[:-1]:
            cursor=cursor.setdefault(key,{})
        cursor[keys[-1]]=value
    
    def __contains__(self,__key) -> bool:
        if __debug__:
            if not isinstance(__key,str):
                raise NotImplementedError("cant access settings collection with something else than a string")
        keys: list[str]=__key.split('.')
        cursor: dict=self._dict
        for key in keys:
            if key not in cursor:
                return False
            cursor=cursor[key]
        return True
    
    def __delitem__(self,__key):
        if __debug__:
            if not isinstance(__key,str):
                raise NotImplementedError("cant access settings collection with something else than a string")
        keys: list[str]=__key.split('.')
        cursor: dict=self._dict
        for key in keys[:-1]:
            cursor=cursor[key]
        del cursor[keys[-1]]
        
class settings_motor():
    def __init__(self,defaults:settings_collection,normal:settings_collection,overrides:settings_collection):
        self._defaults: settings_collection=defaults
        self._normal: settings_collection=normal
        self._overrides: settings_collection=overrides
        

__override: settings_collection = settings_collection() #for eg command line arguments that should be prioritary but without ending saved
__settings: settings_collection = settings_collection()
__defaults: settings_collection = settings_collection()

try:
    path: str = os.path.abspath(os.path.dirname(__file__))
    path = os.path.join(path, "default_settings.json")
    
    with open(path, 'r', encoding="utf-8") as setfile:
        __defaults = settings_collection(json.load(setfile))
        
except Exception as e:
    print("no default_settings.json file, package should be reinstalled or permission checked, aborting", file=stderr)
    raise FileNotFoundError('default_settings.json')

if "--no-settings" in argv:
    print("Using only default settings")
    __override=__defaults
    

path: str = os.path.abspath(os.path.dirname(__file__))
path = os.path.join(path, "settings.json")
    
try:
    with open(path, 'r', encoding="utf-8") as setfile:
        __settings = settings_collection(json.load(setfile))
            
except:
    print("inexistant or ill-formated settings.json file, using defaults settings only")


def get(setloc: str) -> Any:
    path: list[str]=setloc.split('.')
    
    try:
        temp = __settings
        for key in path:
            temp = temp[key]
        return temp
    
    except (KeyError, TypeError):
        try:
            temp = __defaults
            for key in path:
                temp = temp[key]
            return temp
        
        except:
            if get("logging") >= 1:
                print("No setting found for ", setloc, file=stderr)
            return None


def set(setloc: str, value) -> bool:
    """Définit les paramètres 'setloc' à la valeur value.

    Args:
        setloc (str): Paramètre à mettre à jour, un fichier. Permit de séparer par groupe (par exemple "group.sub.setting")
        value (any): La nouvelle valeur du paramètre, doit être représentable en json

    Returns:
        bool: if the update was sucessful
    """
    temp = __settings
    path: list[str]=setloc.split('.')
    
    for key in path[:-1]:
        if type(temp) is not dict:
            if get("logging") >= 1:
                print("setting path to non dict, abborting", file=stderr)
                
            return False
        
        if key not in temp:
            temp[key] = {}
        temp = temp[key]
        
    temp[path[-1]] = value
    
    return True


def save() -> bool:
    """Sauvegarde les changements dans settings.json

    Returns:
        bool: Si les changement on pu se faire
    """
    
    try:
        with open(path, 'w', encoding="utf-8") as setfile:
            json.dump(__settings, setfile, indent=2)
            return True
        
    except Exception as e:
        if get("logging") >= 1:
            print("Illegal setting for json representation or no write acess:", e, file=stderr)
            
        return False