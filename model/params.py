from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from configparser import ConfigParser
import math

# Params class save settings
class Params(QObject):
    updated = Signal()

    def __init__(self, parent=None, file="params.ini"):
        super().__init__(parent)
        self._file = file
        self._n = 10
        self._f = 6489600
        self._r = 3
        self._p = 0
        self._anchors = [
            [0.00, 2.52, 0.85, 1.00],
            [1.75, 2.52, 0.85, 1.00],
            [0.85, 1.40, 1.50, 1.00],
            [0.00, 1.50, 0.88, 1.00],
            [1.75, 1.50, 0.88, 1.00],
            [0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00]
        ]

        self._car_w = 2.4
        self._car_h = 5.5
        self._car_off_x = 0.3
        self._car_off_y = 0.1

        self._configs = ConfigParser()
        try:
            if self._file:
                self._configs.read(self._file)
                self.parse_config(self._configs)
        except Exception as ex:
            print(ex)

    def __del__(self):
        self.save()

    def parse_config(self, configs):
        try:
            if 'PARAMS' in configs:
                params = configs['PARAMS']
                try:
                    n = int(params.get('N', 10))
                    if not math.isnan(n):
                        self._n = n
                    else:
                        self._n = 10
                except Exception as _:
                    pass

                try:
                    f = int(params.get('F', 6489600))
                    if not math.isnan(f):
                        self._f = f
                    else:
                        self._f = 6489600
                except Exception as _:
                    pass

                try:
                    r = int(params.get('R', 3))
                    if not math.isnan(r):
                        self._r = r
                    else:
                        self._r = 3
                except Exception as _:
                    pass

                try:
                    p = int(params.get('P', 0))
                    if not math.isnan(p):
                        self._p = p
                    else:
                        self._p = 0
                except Exception as _:
                    pass

                try:
                    car_w = int(params.get('car_w', 0))
                    if not math.isnan(car_w):
                        self._car_w = car_w
                    else:
                        self._car_w = 2.4
                except Exception as _:
                    pass

                try:
                    car_h = int(params.get('car_h', 0))
                    if not math.isnan(car_h):
                        self._car_h = car_h
                    else:
                        self._car_h = 5.5
                except Exception as _:
                    pass

                try:
                    car_off_x = int(params.get('car_off_x', 0))
                    if not math.isnan(car_off_x):
                        self._car_off_x = car_off_x
                    else:
                        self._car_off_x = 0.3
                except Exception as _:
                    pass

                try:
                    car_off_y = int(params.get('car_off_y', 0))
                    if not math.isnan(car_off_y):
                        self._car_off_y = car_off_y
                    else:
                        self._car_off_y = 0.1
                except Exception as _:
                    pass

                for i in range(len(self._anchors)):
                    a = params.get('anchor' + str(i+1), '0.00, 0.00, 0.00, 0.00')
                    try:
                        b = a.split(',')
                        for j in range(4):
                            try:
                                c = float(b[j])
                                if not math.isnan(c):
                                    self._anchors[i][j] = c
                                else:
                                    self._anchors[i][j] = 0
                            except Exception as _:
                                self._anchors[i][j] = 0
                    except Exception as _:
                        pass
        except Exception as _:
            pass

    def get_n(self):
        return self._n

    def set_n(self, value):
        if self._n != value:
            self._n = value
            self.updated.emit()

    def get_f(self):
        return self._f

    def set_f(self, value):
        if self._f != value:
            self._f = value
            self.updated.emit()

    def get_r(self):
        return self._r

    def set_r(self, value):
        if self._r != value:
            self._r = value
            self.updated.emit()

    def get_p(self):
        return self._p

    def set_p(self, value):
        if self._p != value:
            self._p = value
            self.updated.emit()

    def get_car_w(self):
        return self._car_w

    def set_car_w(self, value):
        if self._car_w != value:
            self._car_w = value
            self.updated.emit()

    def get_car_h(self):
        return self._car_h

    def set_car_h(self, value):
        if self._car_h != value:
            self._car_h = value
            self.updated.emit()

    def get_car_off_x(self):
        return self._car_off_x

    def set_car_off_x(self, value):
        if self._car_off_x != value:
            self._car_off_x = value
            self.updated.emit()

    def get_car_off_y(self):
        return self._car_off_y

    def set_car_off_y(self, value):
        if self._car_off_y != value:
            self._car_off_y = value
            self.updated.emit()

    def get_anchors(self):
        return self._anchors

    def set_anchors(self, value):
        if self._anchors != value:
            self._anchors = value
            self.updated.emit()

    @Slot(int, int, str)
    def set_anchor(self, i, j, p):
        if (not math.isnan(float(p))) and self._anchors[i][j] != float(p):
            self._anchors[i][j] = float(p)
            self.updated.emit()

    def save(self):
        self._configs['PARAMS'] = {
            'N': str(self._n),
            'F': str(self._f),
            'R': str(self._r),
            'P': str(self._p),
            'car_w': str(self._car_w),
            'car_h': str(self._car_h),
            'car_off_x': str(self._car_off_x),
            'car_off_y': str(self._car_off_y)
        }

        for i in range(len(self._anchors)):
            self._configs['PARAMS']['anchor'+str(i+1)] = f"{self._anchors[i][0]}, {self._anchors[i][1]}, {self._anchors[i][2]}, {self._anchors[i][3]}"

        if self._file:
            with open(self._file, 'w') as configfile:
                self._configs.write(configfile)

    N = Property(int, fget=get_n, fset=set_n, notify=updated)
    F = Property(int, fget=get_f, fset=set_f, notify=updated)
    R = Property(int, fget=get_r, fset=set_r, notify=updated)
    P = Property(int, fget=get_p, fset=set_p, notify=updated)
    CarWidth = Property(float, fget=get_car_w, fset=set_car_w, notify=updated)
    CarHeight = Property(float, fget=get_car_h, fset=set_car_h, notify=updated)
    CarOffsetX = Property(float, fget=get_car_off_x, fset=set_car_off_x, notify=updated)
    CarOffsetY = Property(float, fget=get_car_off_y, fset=set_car_off_y, notify=updated)
    anchors = Property("QVariantList", fget=get_anchors, fset=set_anchors, notify=updated)
