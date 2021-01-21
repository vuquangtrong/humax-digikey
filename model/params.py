from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot

class Params(QObject):

    ### SIGNALS
    updated = Signal()


    ### METHODS
    def __init__(self, parent=None, x=-1000.0, y=-1000.0):
        super().__init__(parent)
        self.__N = 100
        self.__F = 6489600
        self.__R = 3
        self.__P = 0


    def get_N(self):
        #print("get_N", self.__N)
        return self.__N

    def set_N(self, value):
        if value != self.__N:
            self.__N = value
            #print("set_N", self.__N)
            self.updated.emit()

    def get_F(self):
        #print("get_F", self.__F)
        return self.__F

    def set_F(self, value):
        if value != self.__F:
            self.__F = value
            #print("set_F", self.__F)
            self.updated.emit()
    
    def get_R(self):
        #print("get_N", self.__N)
        return self.__R

    def set_R(self, value):
        if value != self.__R:
            self.__R = value
            #print("set_R", self.__R)
            self.updated.emit()

    def get_P(self):
        #print("get_P", self.__P)
        return self.__P

    def set_P(self, value):
        if value != self.__P:
            self.__P = value
            #print("set_P", self.__P)
            self.updated.emit()
    
    ## PROPERTIES
    N = Property(int, fget=get_N, fset=set_N, notify=updated)
    F = Property(int, fget=get_F, fset=set_F, notify=updated)
    R = Property(int, fget=get_R, fset=set_R, notify=updated)
    P = Property(int, fget=get_P, fset=set_P, notify=updated)
   