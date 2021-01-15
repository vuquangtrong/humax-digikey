from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from model.repeat_timer import RepeatTimer
from model.position import Position
from model.anchor import Anchor
from model.params import Params

#### FROM DEVICE ####
# synchronous mode  #
from model.digikey_from_device import DigiKeyFromDevice
from model.digikey_from_log import DigiKeyFromLog

#### FROM LOG FILE ####
# asynchronous mode   #

# main function, of course ^^
def main():
    # install helper to print qt/qml message
    # OR select 'emulate terminal in output console' in Run settings
    # QtCore.qInstallMessageHandler(lambda mode, ctx, msg: print(msg))

    # create QT Application
    app = QApplication()

    # create backend object
    digikey_from_device = DigiKeyFromDevice()
    digikey_from_log = DigiKeyFromLog()

    # create QML engine
    qml_engine = QQmlApplicationEngine()

    # get context
    context = qml_engine.rootContext()

    # expose custom type
    qmlRegisterType(Position, 'Position', 1, 0, 'Position')

    # expose backend to QML
    context.setContextProperty("obj_DigiKeyFromDevice", digikey_from_device)
    context.setContextProperty("obj_DigiKeyFromLog", digikey_from_log)

    # load UI
    print("Start UI")
    qml_engine.load(QtCore.QUrl("ui/main.qml"))
    if not qml_engine.rootObjects():
        print("Can NOT load QML file")
        exit(-1)

    # start
    app.exec_()

    # clean up
    digikey_from_device.deinit()
    digikey_from_log.deinit()


if __name__ == '__main__':
    main()
