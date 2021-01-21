from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot

class Anchor(QObject):

    ### SIGNALS
    updated = Signal()


    ### METHODS
    def __init__(self, parent=None):
        super().__init__(parent)
        self.__is_working = False
        self.__coordinate = [0.0 for _ in range(3)] # x, y, z

    def get_working_status(self):
        #print("get_working_status", self.__is_working)
        return self.__is_working
    

    def set_working_status(self, value):
        if value != self.__is_working:
            self.__is_working = value
            #print("set_working_status", self.__is_working)
            self.updated.emit()


    def get_coordinate(self):
        #print("get_coordinate", self.__coordinate)
        return self.__coordinate


    def set_coordinate(self, value):
        if value != self.__coordinate:
            self.__coordinate = value
            #print("set_coordinate", self.__coordinate)
            self.updated.emit()


    ## PROPERTIES
    isWorking = Property(bool, fget=get_working_status, fset=set_working_status, notify=updated)
    coordinate = Property('QVariantList', fget=get_coordinate, fset=set_coordinate, notify=updated)
