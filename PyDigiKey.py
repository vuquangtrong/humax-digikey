
from random import random, randrange
from configparser import ConfigParser
from threading import Timer
from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

###############################
# CHANGE BELOW LIB ON REAL HW #
###############################
from ui_range_forTest import ui_range


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


# Params class save settings
class Params(QObject):
    updated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._n = 10
        self._f = 6489600
        self._r = 3
        self._p = 0
        self._anchors = [
            [0, 0, 0],
            [2, 0, 0],
            [2, 5, 0],
            [0, 5, 0],
            [0, 1.5, 0],
            [2, 1.5, 0],
            [2, 3.5, 0],
            [0, 3.5, 0]
        ]

        self._configs = ConfigParser()
        try:
            self._configs.read("params.ini")
            #self.read_config(self._configs)
        except Exception as ex:
            print(ex)

    def __del__(self):
        self.save()

    def read_config(self, configs):
        try:
            if 'PARAMS' in configs:
                params = configs['PARAMS']
                n = params.get('N', 10)
                try:
                    self.N = int(n)
                except Exception as _:
                    pass

                f = params.get('F', 6489600)
                try:
                    self.F = int(f)
                except Exception as _:
                    pass

                r = params.get('R', 3)
                try:
                    self.F = int(r)
                except Exception as _:
                    pass

                p = params.get('P', 0)
                try:
                    self.F = int(p)
                except Exception as _:
                    pass

                for i in range(len(self._anchors)):
                    a = params.get('anchor' + str(i+1), '0,0,0')
                    try:
                        b = a.split(',')
                        for j in range(3):
                            try:
                                self._anchors[i][j] = float(b[j])
                            except Exception as _:
                                self._anchors[i][j] = 0
                    except Exception as _:
                        pass
        except Exception as ex:
            print(ex)

    def get_n(self):
        return self._n

    def set_n(self, value):
        self._n = value
        self.updated.emit()

    def get_f(self):
        return self._f

    def set_f(self, value):
        self._f = value
        self.updated.emit()

    def get_r(self):
        return self._r

    def set_r(self, value):
        self._r = value
        self.updated.emit()

    def get_p(self):
        return self._p

    def set_p(self, value):
        self._p = value
        self.updated.emit()

    def get_anchors(self):
        return self._anchors

    def set_anchors(self, value):
        self._anchors = value
        self.updated.emit()

    @Slot(int, int, str)
    def set_anchor(self, i, j, p):
        try:
            self._anchors[i][j] = float(p)
            self.updated.emit()
        except Exception as ex:
            popup = QMessageBox(QMessageBox.Critical, "Critical", "Wrong format!!!\n" + str(ex))
            popup.exec_()

    def save(self):
        self._configs['PARAMS'] = {
            'N': str(self._n),
            'F': str(self._f),
            'R': str(self._r),
            'P': str(self._p)
        }

        for i in range(len(self._anchors)):
            self._configs['PARAMS']['anchor'+str(i+1)] = f"{self._anchors[i][0]}, {self._anchors[i][1]}, {self._anchors[i][2]}"

        with open('params.ini', 'w') as configfile:
            self._configs.write(configfile)

    N = Property(int, fget=get_n, fset=set_n, notify=updated)
    F = Property(int, fget=get_f, fset=set_f, notify=updated)
    R = Property(int, fget=get_r, fset=set_r, notify=updated)
    P = Property(int, fget=get_p, fset=set_p, notify=updated)
    anchors = Property("QVariantList", fget=get_anchors, fset=set_anchors, notify=updated)


# DigiKey holds data as backend
class DigiKey(QObject):
    paramsUpdated = Signal()
    positionUpdated = Signal(int)
    anchorsUpdated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._params = Params()
        self._params.updated.connect(self.on_params_updated)

        self._position = Position()
        self._position_history = [[0 for _ in range(60)] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[0 for _ in range(60)] for _ in range(len(self._position.distance))]
        self._anchors = [Anchor() for _ in range(8)]

        self._ui_range = ui_range()
        self._initialized = False
        self._started = False

        self._update_timer = RepeatTimer(1, self.update_ui)
        self._update_timer.start()

    def __del__(self):
        self.deinit()

    def deinit(self):
        self._update_timer.cancel()

    def get_params(self):
        return self._params

    def set_params(self, value):
        self._params = value

    def on_params_updated(self):
        self.paramsUpdated.emit()

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
        if self._started:
            '''
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
            '''
            ################
            # USE UI_RANGE #
            ################

            # get location
            position_status = 0
            try:
                x, y = self._ui_range.getLocation()
                if x == 'nodata':
                    position_status = -1
                if x == 'wrong':
                    position_status = -2

                self._position.coordinate[0] = float(x)
                self._position.coordinate[1] = float(y)
                position_status = 1

                for i in range(len(self._position.coordinate)):
                    self._position_history[i].pop(0)
                    self._position_history[i].append(self._position.coordinate[i])
            except Exception as ex:
                print(ex)

            # get performance
            for i in range(len(self._anchors)):
                try:
                    performance = self._ui_range.getAnchorPerformance(i)
                    self._anchors[i].RSSI = performance[0]
                    self._anchors[i].SNR = performance[1]
                    self._anchors[i].NEV = performance[2]
                    self._anchors[i].NER = performance[3]
                    self._anchors[i].PER = performance[4]
                except Exception as ex:
                    print(ex)

            # notify
            self.positionUpdated.emit(position_status)
            self.anchorsUpdated.emit()

    params = Property(Params, fget=get_params, fset=set_params, notify=paramsUpdated)
    position = Property(Position, fget=get_position, fset=set_position, notify=positionUpdated)
    positionHistory = Property("QVariantList", fget=get_position_history, notify=positionUpdated)
    distanceHistory = Property("QVariantList", fget=get_distance_history, notify=positionUpdated)
    anchors = Property("QVariantList", fget=get_anchors, notify=anchorsUpdated)

    @Slot()
    def request_init(self):
        print("Init")
        if not self._initialized:
            try:
                self._ui_range.setIteration(self._params.N)
                anchors_location = []
                for anchor in self._params.anchors:
                    for x in anchor:
                        anchors_location.append(x)
                self._ui_range.setAnchorLocation(anchors_location)
                self._ui_range.setCfg(configID=self._params.R, channel_frequency=self._params.F, nominal_tx_power=self._params.P)
                self._initialized = True
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Init failed!!!\n" + str(ex))
                popup.exec_()
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "Please stop ranging before you can init new configs")
            popup.exec_()

    @Slot()
    def request_start(self):
        print("Start")
        if self._initialized:
            if not self._started:
                try:
                    self._ui_range.startRanging()
                    self._started = True
                except Exception as ex:
                    popup = QMessageBox(QMessageBox.Critical, "Critical", "Start failed!!!\n" + str(ex))
                    popup.exec_()
            else:
                popup = QMessageBox(QMessageBox.Warning, "Warning", "Ranging is already started")
                popup.exec_()
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "You must init first")
            popup.exec_()

    @Slot()
    def request_record(self):
        print("<Not implemented> Record")

    @Slot()
    def request_stop(self):
        if self._started:
            self._started = False
            self._initialized = False
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "Ranging is not running")
            popup.exec_()

    @Slot()
    def request_clear_history(self):
        self._position_history = [[0 for _ in range(60)] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[0 for _ in range(60)] for _ in range(len(self._position.distance))]


# main function, of course ^^
def main():
    # install helper to print qt/qml message
    # OR select 'emulate terminal in output console' in Run settings
    # QtCore.qInstallMessageHandler(lambda mode, ctx, msg: print(msg))

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
    print("Start UI")
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
