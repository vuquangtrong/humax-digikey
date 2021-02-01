# Humax PyDigiKey2
# 

# need 
import sys

# need PySide2 from https://wiki.qt.io/Qt_for_Python
from PySide2 import QtCore
from PySide2.QtWidgets import QApplication
from PySide2.QtQml import QQmlApplicationEngine

# data models
from model.digikey_from_log import DigiKeyFromLog
from model.location import Location
from model.anchor import Anchor
from model.ble import BLE

def main():
    # QT Window App
    app = QApplication()

    # Data model
    digikey_from_log = DigiKeyFromLog()

    # QML engine
    qml_engine = QQmlApplicationEngine()

    # Register data model object
    context = qml_engine.rootContext()
    context.setContextProperty("DigiKeyFromLog", digikey_from_log)

    # example to use APIs
    #digikey_from_log.set_ble_zone_status(True)

    # Start UI
    qml_engine.load(QtCore.QUrl.fromLocalFile("ui/__main.qml"))
    if not qml_engine.rootObjects():
        print("Can NOT load QML file")
        exit(-1)

    # Run application
    sys.exit(app.exec_())


# run main when execute this file directly
if __name__ == '__main__':
    main()
