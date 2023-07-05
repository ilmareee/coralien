#  Code sous liscence GPL3+. Plus de détail a <https://www.gnu.org/licenses/> ou dans le fichier LICENCE
# encoding = utf8
import json
from operator import delitem
import os
from typing import Any
from sys import stderr, argv


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
    
    def __delitem__(self,__key) -> None:
        if __debug__:
            if not isinstance(__key,str):
                raise NotImplementedError("cant access settings collection with something else than a string")
        keys: list[str]=__key.split('.')
        cursor: dict=self._dict
        for key in keys[:-1]:
            cursor=cursor[key]
        del cursor[keys[-1]]
        
class settings_motor():
    def __init__(self,defaults:settings_collection,normal:settings_collection,overrides:settings_collection,config_path:str) -> None:
        self._defaults: settings_collection=defaults
        self._normal: settings_collection=normal
        self._overrides: settings_collection=overrides
        self._default_path=config_path
    
    def __getitem__(self,__key:str) -> Any:
        for sett in (self._overrides,self._normal,self._defaults):
            if __key in sett:
                return sett[__key]
        return None
    
    def __setitem__(self,__key,value) -> None:
        if __key in self._overrides:
            del self._overrides[__key]
        self._normal[__key]=value
    
    def setdefault(self,key:str) -> None:
        for sett in (self._overrides,self._normal):
            if key in sett:
                del sett[key]
    
    def save(self,path:str=None) -> None:
        if path is None:
            path=self._default_path
        try:
            with open(path, 'w', encoding="utf-8") as setfile:
                json.dump(self._normal._dict, setfile, indent=2)
        except:
            if settings["logging"]>=1:
                print("Could not write settings in",path)
    
    def override(self,key,value):
        self._overrides[key]=value


__override: settings_collection = settings_collection() #for eg command line arguments that should be prioritary but without ending saved
__normal: settings_collection = settings_collection()
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
    print("--no-settings specified: Using only default and command line settings")
    __override=__defaults

if "--config-file" in argv:
    config_path=argv[argv.index("--config-file")+1]
else:
    if 'APPDATA' in os.environ:
        confighome = os.environ['APPDATA']
    elif 'XDG_CONFIG_HOME' in os.environ:
        confighome = os.environ['XDG_CONFIG_HOME']
    else:
        confighome = os.path.join(os.environ['HOME'], '.config')
    config_path:str = os.path.join(confighome, 'Coralien','settings.json')

    
    
try:
    with open(config_path, 'r', encoding="utf-8") as setfile:
        __normal = settings_collection(json.load(setfile))
            
except:
    print("inexistant or ill-formated settings.json file, using defaults settings only")
    __normal=settings_collection()

settings=settings_motor(__defaults,__normal,__override,config_path)
del __override,__normal,__defaults

if '--verbose' in argv:
    settings.override("logging",2)

if '--debug' in argv:
    settings.override("logging",3)
