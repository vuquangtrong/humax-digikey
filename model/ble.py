from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot

class BLE(QObject):

    ### SIGNALS
    updated = Signal()


    ### METHODS
    def __init__(self, parent=None):
        super().__init__(parent)
        self.__status = 0
        self.__rssi = -1000
        self.__door_count = 0
        self.__trunk_count = 0
        self.__engine_count = 0


    def get_status(self):
        #print("get_status", self.__status)
        return self.__status
    

    def set_status(self, value):
        if value != self.__status:
            self.__status = value
            #print("set_status", self.__status)
            self.updated.emit()


    def get_rssi(self):
        #print("get_rssi", self.__rssi)
        return self.__rssi


    def set_rssi(self, value):
        if value != self.__rssi:
            self.__rssi = value
            #print("set_rssi", self.__rssi)
            self.updated.emit()


    def get_door_count(self):
        #print("get_door_count", self.__door_count)
        return self.__door_count


    def set_door_count(self, value):
        if value != self.__door_count:
            self.__door_count = value
            #print("set_door_count", self.__door_count)
            self.updated.emit()
    

    def get_trunk_count(self):
        #print("get_trunk_count", self.__trunk_count)
        return self.__trunk_count


    def set_trunk_count(self, value):
        if value != self.__trunk_count:
            self.__trunk_count = value
            #print("set_trunk_count", self.__trunk_count)
            self.updated.emit()
    

    def get_engine_count(self):
        #print("get_engine_count", self.__engine_count)
        return self.__engine_count


    def set_engine_count(self, value):
        if value != self.__engine_count:
            self.__engine_count = value
            #print("set_engine_count", self.__engine_count)
            self.updated.emit()


    ## PROPERTIES
    status = Property(int, fget=get_status, fset=set_status, notify=updated)
    rssi = Property(int, fget=get_rssi, fset=set_rssi, notify=updated)
    doorCount = Property(int, fget=get_door_count, fset=set_door_count, notify=updated)
    trunkCount = Property(int, fget=get_trunk_count, fset=set_trunk_count, notify=updated)
    engineCount = Property(int, fget=get_engine_count, fset=set_engine_count, notify=updated)
