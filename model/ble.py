from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot


from configparser import ConfigParser

BLE_CONFIG_FILE= "ui/ble.ini"

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

        self.__config_file = ConfigParser()
        self.__radius = 500
        self.__x = 0
        self.__y = 0
        self.__isShowingZone = False

        self.read_config()

    def read_config(self):
        self.__config_file.read(BLE_CONFIG_FILE)
        if 'BLE' in self.__config_file:
            configs = self.__config_file['BLE']

            try:
                w = int(configs.get("radius", 1000))
                self.set_radius(w)
            except Exception as ex:
                print(ex)

            try:
                x = int(configs.get("x", 460))
                self.set_x(x)
            except Exception as ex:
                print(ex)
            
            try:
                y = int(configs.get("y", 460))
                self.set_y(y)
            except Exception as ex:
                print(ex)

    def save_config(self):
        self.__config_file.read(BLE_CONFIG_FILE)
        if not 'BLE' in self.__config_file:
            self.__config_file.add_section('BLE')
        
        self.__config_file['BLE']['radius'] = str(self.__radius)
        self.__config_file['BLE']['x'] = str(self.__x)
        self.__config_file['BLE']['y'] = str(self.__y)

        with open(BLE_CONFIG_FILE, "w") as config_file:
            self.__config_file.write(config_file)

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

    def get_radius(self):
        #print("get_radius", self.__radius)
        return self.__radius

    def set_radius(self, value):
        if value != self.__radius:
            self.__radius = value
            #print("set_radius", self.__radius)
            self.updated.emit()
    
    def get_x(self):
        #print("get_x", self.__x)
        return self.__x

    def set_x(self, value):
        if value != self.__x:
            self.__x = value
            #print("set_x", self.__x)
            self.updated.emit()
    
    def get_y(self):
        #print("get_y", self.__y)
        return self.__y

    def set_y(self, value):
        if value != self.__y:
            self.__y = value
            #print("set_y", self.__y)
            self.updated.emit()
    
    def get_zone_status(self):
        #print("get_zone_status", self.__isShowingZone)
        return self.__isShowingZone

    def set_zone_status(self, value):
        if value != self.__isShowingZone:
            self.__isShowingZone = value
            #print("set_zone_status", self.__isShowingZone)
            self.updated.emit()
    
    ## PROPERTIES
    status = Property(int, fget=get_status, fset=set_status, notify=updated)
    rssi = Property(int, fget=get_rssi, fset=set_rssi, notify=updated)
    doorCount = Property(int, fget=get_door_count, fset=set_door_count, notify=updated)
    trunkCount = Property(int, fget=get_trunk_count, fset=set_trunk_count, notify=updated)
    engineCount = Property(int, fget=get_engine_count, fset=set_engine_count, notify=updated)
    radius = Property(int, fget=get_radius, fset=set_radius, notify=updated)
    x = Property(int, fget=get_x, fset=set_x, notify=updated)
    y = Property(int, fget=get_y, fset=set_y, notify=updated)
    isShowingZone = Property(bool, fget=get_zone_status, fset=set_zone_status, notify=updated)
