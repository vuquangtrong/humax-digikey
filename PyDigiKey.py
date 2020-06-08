from datetime import datetime
from threading import Timer
from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType


# modify base Timer class to make a repetitive Timer
class RepeatTimer(Timer):
    def __init__(self, interval, function, args=None, kwargs=None):
        super().__init__(interval, function, args, kwargs)

    # override
    def run(self):
        # make while loop
        while not self.finished.is_set():
            self.finished.wait(self.interval)
            self.function(*self.args, **self.kwargs)
        self.finished.set()


# Position holds the coordinate value
class Position(QObject):
    updated = Signal()

    def __init__(self, parent=None, x=0.0, y=0.0, z=0.0):
        super().__init__(parent)
        self._x = x
        self._y = y
        self._z = z

    def __str__(self):
        return f"({self._x}, {self._y}, {self._z})"

    def getx(self):
        return self._x

    def setx(self, x):
        self._x = x

    def gety(self):
        return self._y

    def sety(self, y):
        self._y = y

    def getz(self):
        return self._z

    def setz(self, z):
        self._z = z

    x = Property(float, fget=getx, fset=setx, notify=updated)
    y = Property(float, fget=gety, fset=sety, notify=updated)
    z = Property(float, fget=getz, fset=setz, notify=updated)


# DigiKey holds data as backend
class DigiKey(QObject):
    receiverStatusChanged = Signal()
    positionUpdated = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._receiverStatus = "Waiting..."
        self._position = Position()
        self._updateTimer = RepeatTimer(1, self.update_ui)
        self._updateTimer.start()

    def __del__(self):
        self.deinit()

    def deinit(self):
        self._updateTimer.cancel()

    def position(self):
        return self._position

    def receiverStatus(self):
        return self._receiverStatus

    def update_ui(self):
        self.update_position()

    def update_position(self):
        # update calculated position
        self._position.x += 1
        self._position.y += 2

        # print timestamp
        print(datetime.now(), self.position)

        # make decorated text
        msg = "Location update " + "<font color=\"#FF0000\">" + str(self.position) + "</font>" + "<br>" + \
            "D1 = 0.00, D2 = 0.00, D3 = 0.00, D4 = 0.00" + "<br>" + \
            "D4 = 0.00, D5 = 0.00, D6 = 0.00, D7 = 0.00" + "<br>" + "<br>"

        # notify
        self.positionUpdated.emit(msg)

    receiverStatus = Property(str, fget=receiverStatus, notify=receiverStatusChanged)
    position = Property(Position, fget=position, notify=positionUpdated)

    @Slot()
    def request_init(self):
        print("<Not implemented> Init")

    @Slot()
    def request_start(self):
        print("<Not implemented> Start")

    @Slot()
    def request_record(self):
        print("<Not implemented> Record")

    @Slot()
    def request_stop(self):
        print("<Not implemented> Stop")


# main function, of course ^^
def main():
    # install helper to print qt/qml message
    # in PyCharm, select 'emulate
    QtCore.qInstallMessageHandler(lambda mode, ctx, msg: print(msg))

    # create backend object
    digikey = DigiKey()

    # create QT Application
    app = QGuiApplication()

    # create QML engine
    qml_engine = QQmlApplicationEngine()

    # get context
    context = qml_engine.rootContext()

    # expose custom type
    qmlRegisterType(Position, 'Position', 1, 0, 'Position')

    # expose backend to QML
    context.setContextProperty("DigiKey", digikey)

    # load UI
    qml_engine.load(QtCore.QUrl("DigiKeyUI/main.qml"))
    if not qml_engine.rootObjects():
        print("Can NOT load QML file")
        exit(-1)

    # start
    app.exec_()

    # clean up
    digikey.deinit()


if __name__ == '__main__':
    main()
