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

    def __init__(self, parent=None):
        super().__init__(parent)
        self._coordinate = [0.0] * 3  # x, y, z
        self._distance = [0.0] * 8  # D1 ~ D8

    def get_coordinate(self):
        return self._coordinate

    def set_coordinate(self, value):
        self._coordinate = value

    def get_distance(self):
        return self._distance

    def set_distance(self, value):
        self._distance = value

    # PySide2 does not natively convert python list to QVariantList, must use it explicitly
    coordinate = Property("QVariantList", fget=get_coordinate, fset=set_coordinate, notify=updated)
    distance = Property("QVariantList", fget=get_distance, fset=set_distance, notify=updated)


# DigiKey holds data as backend
class DigiKey(QObject):
    receiverStatusChanged = Signal()
    positionUpdated = Signal(Position)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._receiver_status = "Waiting..."
        self._position = Position()
        self._update_timer = RepeatTimer(1, self.update_ui)
        self._update_timer.start()

    def __del__(self):
        self.deinit()

    def deinit(self):
        self._update_timer.cancel()

    def get_receiver_status(self):
        return self._receiver_status

    def set_receiver_status(self, value):
        self._receiver_status = value

    def get_position(self):
        return self._position

    def set_position(self, value):
        self._position = value

    def update_ui(self):
        self.update_position()

    def update_position(self):
        # update calculated position
        self.position.coordinate[0] += 5
        self.position.coordinate[1] += 10

        for i in range(len(self.position.distance)):
            self.position.distance[i] = i

        # print timestamp
        print(datetime.now())

        # notify
        self.positionUpdated.emit(self.position)

    receiverStatus = Property(str, fget=get_receiver_status, fset=set_receiver_status, notify=receiverStatusChanged)
    position = Property(Position, fget=get_position, fset=set_position, notify=positionUpdated)

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
