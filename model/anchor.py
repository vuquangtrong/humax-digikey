from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

# Anchor class with its performance data
class Anchor(QObject):
    updated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rssi = 0.0
        self._snr = 0.0
        self._nev = 0.0
        self._ner = 0.0
        self._per = 0.0
        self._active = False

    def get_rssi(self):
        return self._rssi
    
    def set_rssi(self, value):
        if self._rssi != value:
            self._rssi = value
            self.updated.emit()

    def get_snr(self):
        return self._snr

    def set_snr(self, value):
        if self._snr != value:
            self._snr = value
            self.updated.emit()
    
    def get_nev(self):
        return self._nev

    def set_nev(self, value):
        if self._nev != value:
            self._nev = value
            self.updated.emit()
    
    def get_ner(self):
        return self._ner

    def set_ner(self, value):
        if self._ner != value:
            self._ner = value
            self.updated.emit()
    
    def get_per(self):
        return self._per

    def set_per(self, value):
        if self._per != value:
            self._per = value
            self.updated.emit()

    def get_active(self):
        return self._active

    def set_active(self, value):
        if self._active != value: 
            self._active = value
            self.updated.emit()

    RSSI = Property(float, fget=get_rssi, fset=set_rssi, notify=updated)    
    SNR = Property(float, fget=get_snr, fset=set_snr, notify=updated)
    NEV = Property(float, fget=get_nev, fset=set_nev, notify=updated)
    NER = Property(float, fget=get_ner, fset=set_ner, notify=updated)
    PER = Property(float, fget=get_per, fset=set_per, notify=updated)
    active = Property(bool, fget=get_active, fset=set_active, notify=updated)
