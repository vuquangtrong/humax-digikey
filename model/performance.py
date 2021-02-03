import copy

from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot

class Performance(QObject):

    ### SIGNALS
    updated = Signal()


    ### METHODS
    def __init__(self, parent=None, x=-1000.0, y=-1000.0, origin=None):
        super().__init__(parent)
        if origin is None:
            self.__RSSI = 0
            self.__SNR = 0
            self.__NEV = 0
            self.__NER = 0
            self.__PER = 0
            self.__MPWR = 0
        else:
            self.__RSSI = copy.deepcopy(origin.__RSSI)
            self.__SNR = copy.deepcopy(origin.__SNR)
            self.__NEV = copy.deepcopy(origin.__NEV)
            self.__NER = copy.deepcopy(origin.__NER)
            self.__PER = copy.deepcopy(origin.__PER)
            self.__MPWR = copy.deepcopy(origin.__MPWR)


    def get_RSSI(self):
        #print("get_RSSI", self.__RSSI)
        return self.__RSSI

    def set_RSSI(self, value):
        if value != self.__RSSI:
            self.__RSSI = value
            #print("set_RSSI", self.__RSSI)
            self.updated.emit()

    def get_SNR(self):
        #print("get_SNR", self.__SNR)
        return self.__SNR

    def set_SNR(self, value):
        if value != self.__SNR:
            self.__SNR = value
            #print("set_SNR", self.__SNR)
            self.updated.emit()
    
    def get_NEV(self):
        #print("get_NEV", self.__NEV)
        return self.__NEV

    def set_NEV(self, value):
        if value != self.__NEV:
            self.__NEV = value
            #print("set_NEV", self.__NEV)
            self.updated.emit()

    def get_NER(self):
        #print("get_NER", self.__NER)
        return self.__NER

    def set_NER(self, value):
        if value != self.__NER:
            self.__NER = value
            #print("set_NER", self.__NER)
            self.updated.emit()

    def get_PER(self):
        #print("get_PER", self.__PER)
        return self.__PER

    def set_PER(self, value):
        if value != self.__PER:
            self.__PER = value
            #print("set_PER", self.__PER)
            self.updated.emit()
    
    def get_MPWR(self):
        #print("get_MPWR", self.__MPWR)
        return self.__MPWR

    def set_MPWR(self, value):
        if value != self.__MPWR:
            self.__MPWR = value
            #print("set_MPWR", self.__MPWR)
            self.updated.emit()
    
    ## PROPERTIES
    RSSI = Property(int, fget=get_RSSI, fset=set_RSSI, notify=updated)
    SNR = Property(int, fget=get_SNR, fset=set_SNR, notify=updated)
    NEV = Property(int, fget=get_NEV, fset=set_NEV, notify=updated)
    NER = Property(int, fget=get_NER, fset=set_NER, notify=updated)
    PER = Property(int, fget=get_PER, fset=set_PER, notify=updated)
    MPWR = Property(int, fget=get_MPWR, fset=set_MPWR, notify=updated)
   