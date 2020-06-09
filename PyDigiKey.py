
from random import random, randrange
from threading import Timer
from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication
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


# Position holds the coordinate value and distances to anchors
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


# Anchor class with its performance data
class Anchor(QObject):
    updated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rssi = 0
        self._snr = 0
        self._nev = 0
        self._ner = 0
        self._per = 0
    
    def get_rssi(self):
        return self._rssi
    
    def set_rssi(self, value):
        self._rssi = value

    def get_snr(self):
        return self._snr

    def set_snr(self, value):
        self._snr = value
    
    def get_nev(self):
        return self._nev

    def set_nev(self, value):
        self._nev = value
    
    def get_ner(self):
        return self._ner

    def set_ner(self, value):
        self._ner = value
    
    def get_per(self):
        return self._per

    def set_per(self, value):
        self._per = value

    RSSI = Property(float, fget=get_rssi, fset=set_rssi, notify=updated)    
    SNR = Property(float, fget=get_snr, fset=set_snr, notify=updated)
    NEV = Property(float, fget=get_nev, fset=set_nev, notify=updated)
    NER = Property(float, fget=get_ner, fset=set_ner, notify=updated)
    PER = Property(float, fget=get_per, fset=set_per, notify=updated)


# DigiKey holds data as backend
class DigiKey(QObject):
    receiverStatusChanged = Signal()
    positionUpdated = Signal(Position)
    anchorUpdated = Signal("QVariantList")

    def __init__(self, parent=None):
        super().__init__(parent)
        self._position = Position()
        self._position_history = [[0 for _ in range(60)] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[0 for _ in range(60)] for _ in range(len(self._position.distance))]
        self._anchors = [Anchor() for _ in range(8)]
        self._update_timer = RepeatTimer(1, self.update_ui)
        self._update_timer.start()

    def __del__(self):
        self.deinit()

    def deinit(self):
        self._update_timer.cancel()

    def get_position(self):
        return self._position

    def set_position(self, value):
        self._position = value

    def get_position_history(self):
        return self._position_history

    def get_distance_history(self):
        return self._distance_history

    def get_anchors(self):
        return self._anchors

    def update_ui(self):
        self.update_position()

    def update_position(self):
        # fill fake data for UI dev
        for i in range(len(self._position.coordinate)):
            self._position.coordinate[i] += randrange(0, 2) * (1 if random() > 0.5 else -1)
            self._position_history[i].pop(0)
            self._position_history[i].append(self._position.coordinate[i])

        for i in range(len(self._position.distance)):
            self._position.distance[i] = randrange(0, 5)
            self._distance_history[i].pop(0)
            self._distance_history[i].append(self._position.distance[i])

        for anchor in self._anchors:
            anchor.RSSI = randrange(-100, 0)
            anchor.SNR = randrange(10, 50)
            anchor.NEV = randrange(0, 9999)
            anchor.NER = randrange(0, 9999)
            anchor.PER = random()

        # notify
        self.positionUpdated.emit(self._position)
        self.anchorUpdated.emit(self._anchors)

    position = Property(Position, fget=get_position, fset=set_position, notify=positionUpdated)
    positionHistory = Property("QVariantList", fget=get_position_history, notify=positionUpdated)
    distanceHistory = Property("QVariantList", fget=get_distance_history, notify=positionUpdated)
    anchors = Property("QVariantList", fget=get_anchors, notify=anchorUpdated)

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

    @Slot()
    def request_clear_history(self):
        self._position_history = [[0 for _ in range(60)] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[0 for _ in range(60)] for _ in range(len(self._position.distance))]


# main function, of course ^^
def main():
    # install helper to print qt/qml message
    # in PyCharm, select 'emulate
    QtCore.qInstallMessageHandler(lambda mode, ctx, msg: print(msg))

    # create backend object
    digikey = DigiKey()

    # create QT Application
    app = QApplication()

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
