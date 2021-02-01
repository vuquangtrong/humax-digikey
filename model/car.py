from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot

from configparser import ConfigParser

CAR_CONFIG_FILE= "ui/car.ini"

class Car(QObject):

    ### SIGNALS
    updated = Signal()


    ### METHODS
    def __init__(self, parent=None):
        super().__init__(parent)
        self.__config_file = ConfigParser()
        self.__width = 180
        self.__height = 460
        self.__x = 1460
        self.__y = 1080

        self.read_config()

    def read_config(self):
        self.__config_file.read(CAR_CONFIG_FILE)
        if 'CAR' in self.__config_file:
            configs = self.__config_file['CAR']

            try:
                w = int(configs.get("width", 180))
                self.set_width(w)
            except Exception as ex:
                print(ex)

            try:
                h = int(configs.get("height", 460))
                self.set_height(h)
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
        self.__config_file.read(CAR_CONFIG_FILE)
        if not 'CAR' in self.__config_file:
            self.__config_file.add_section('CAR')
        
        self.__config_file['CAR']['width'] = str(self.__width)
        self.__config_file['CAR']['height'] = str(self.__height)
        self.__config_file['CAR']['x'] = str(self.__x)
        self.__config_file['CAR']['y'] = str(self.__y)

        with open(CAR_CONFIG_FILE, "w") as config_file:
            self.__config_file.write(config_file)
    
    def get_width(self):
        #print("get_width", self.__width)
        return self.__width

    def set_width(self, value):
        if value != self.__width:
            self.__width = value
            #print("set_width", self.__width)
            self.updated.emit()

    def get_height(self):
        #print("get_height", self.__height)
        return self.__height

    def set_height(self, value):
        if value != self.__height:
            self.__height = value
            #print("set_height", self.__height)
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
    
    ## PROPERTIES
    width = Property(int, fget=get_width, fset=set_width, notify=updated)
    height = Property(int, fget=get_height, fset=set_height, notify=updated)
    x = Property(int, fget=get_x, fset=set_x, notify=updated)
    y = Property(int, fget=get_y, fset=set_y, notify=updated)
   