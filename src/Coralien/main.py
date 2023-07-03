# encoding=utf8

import sys
from typing import NoReturn

try:
    from . import settings
except Exception as e:
    print("""The settings engine crashed on startup, probably due to an incorect default_settings.json
          Please do not update it by hand. If this bug appear even without modification to default_settings.json, please report the bug""")
    raise e

from . import affichage

def launch_app() -> NoReturn:
    sys.exit(affichage.app.exec_())