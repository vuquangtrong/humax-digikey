import sys
import math
from random import randint

from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot, QTimer
from PySide2.QtQml import qmlRegisterType

from configparser import ConfigParser
from ast import literal_eval

from .location import Location
from .anchor import Anchor
from .params import Params
from .ble import BLE
from .performance import Performance
from .car import Car


###############################
# CHANGE BELOW LIB ON REAL HW #
###############################
from ui_range_forTest import ui_range

###############################
# Read below log files
###############################
UWB_CONFIG_FILE= "log/uwbconfig.cfg"
UWB_LOCATION_LOG_FILE = "log/locating_data.txt"
UWB_BLE_INFO_FILE = "log/ble_info.txt"

UPDATE_INTERVAL = 300 # ms

class DigiKeyFromLog(QObject):

    # SIGNALS
    carUpdated = Signal()
    bleUpdated = Signal()
    settingsUpdated = Signal()
    locationsUpdated = Signal()
    currentLocationChanged = Signal()
    isRangingChanged = Signal()
    isReadingLogChanged = Signal()
    isAutoplayChanged = Signal()

    # METHODS
    def __init__(self, parent=None):
        super().__init__(parent)

        # Register custom types
        qmlRegisterType(Location, 'Location', 1, 0, 'Location')
        qmlRegisterType(Anchor, 'Anchor', 1, 0, 'Anchor')
        qmlRegisterType(BLE, 'BLE', 1, 0, 'BLE')
        qmlRegisterType(Params, 'Params', 1, 0, 'Params')
        qmlRegisterType(Performance, 'Performance', 1, 0, 'Performance')
        qmlRegisterType(Car, 'Car', 1, 0, 'Car')

        self.__uwb_config_file = ConfigParser()
        self.__uwb_location_log_file = ConfigParser()
        self.__uwb_ble_info_file = ConfigParser()
        
        self.__car = Car()
        self.__ble = BLE()
        self.__params = Params()
        self.__anchors = [Anchor() for _ in range(8)] # A1 ~ A8
        self.__locations = {'loop 0' : Location()}
        self.__location_current_index = 0

        self.__ui_range = ui_range()

        self.__is_ranging = False
        self.__is_reading_log = False
        self.__is_autoplay = True

        # read configs
        self.read_config()

        # read log
        self.__update_timer = QTimer()
        self.__update_timer.timeout.connect(self.update)
        self.__update_timer.start(UPDATE_INTERVAL)

    def read_config(self):
        self.__uwb_config_file.read(UWB_CONFIG_FILE)
        
        if 'uwb config' in self.__uwb_config_file:
            configs = self.__uwb_config_file['uwb config']

            try:
                n = int(configs.get('intervaltime_ranging', 100))
                #print("read_config", "intervaltime_ranging", n)
                self.__params.N = 0 if math.isnan(n) else n
            except Exception as _:
                pass

            try:
                f = int(configs.get('frequency', 6489600))
                #print("read_config", "frequency", f)
                self.__params.F = 6489600 if math.isnan(f) else f
            except Exception as _:
                pass

            try:
                r = int(configs.get('rxcfgindex', 0))
                #print("read_config", "rxcfgindex", r)
                self.__params.R = 0 if math.isnan(r) else r
            except Exception as _:
                pass
            
            try:
                #p = int(params.get('powermode', 0))
                p = int(configs.get('txpower', 0))
                #print("read_config", "txpower", p)
                self.__params.P = 0 if math.isnan(p) else p
            except Exception as _:
                pass
        
        for anchor in self.__anchors:
            anchor.isWorking = False
        
        if 'config on host' in self.__uwb_config_file:
            configs = self.__uwb_config_file['config on host']

            try:
                working_devices = str.split(configs.get('workingdeviceids', ''), ',')
                #print("read_config", "workingdeviceids", working_devices)
                for device in working_devices:
                    self.__anchors[int(device)-1].isWorking = True       
            except Exception as _:
                pass
        
        if 'locating' in self.__uwb_config_file:
            configs = self.__uwb_config_file['locating']
            for i in range(8):
                try:
                    location = literal_eval(configs.get(f"d{i+1}_location", "[0.0, 0.0, 0.0]"))
                    #print("read_config", f"anchor {i+1} at", location)
                    for j in range(1, 4):
                        try:
                            self.__anchors[i].coordinate = location
                        except Exception as _:
                            pass         
                except Exception as _:
                    pass 
    
    def read_log(self):
        if self.__is_reading_log:
            # read log file again
            # do not open and hold
            self.__uwb_location_log_file.read(UWB_LOCATION_LOG_FILE)

            # scan all sections
            for section_name in self.__uwb_location_log_file:    
                if section_name.startswith("loop") and (not section_name in self.__locations):
                    #print("\n==========")
                    #print("section_name", section_name)
                    location = Location()
                    section = self.__uwb_location_log_file[section_name]

                    # check if section is complete
                    finished = int(section.get("loopFinish", 0))
                    if finished != 1:
                        #print("section is incomplete !!!")
                        continue
                    
                    # read location
                    try:
                        keylocation = literal_eval(section.get("keylocation", "[0.0, 0.0, 0.0]"))
                        location.coordinate = keylocation
                        #print("keylocation", keylocation)
                    except Exception as ex:
                        print(ex)
                    
                    # read distance
                    try:
                        for i in range(8):
                            d = float(section.get(f"d{i+1}_distance", 0))
                            #print(f"d{i+1}_distance =", d)
                            location.distance[i] = -1.0 # 
                            if d >= 0 and d <= 20.0:
                                location.distance[i] = d
                    except Exception as ex:
                        print(ex)
                    
                    # read activated anchors
                    try:
                        for anchor in location.activatedAnchors:
                            anchor = False
                        
                        cal_devices = literal_eval(section.get("cal_devices", "[]"))
                        #print("cal_devices", cal_devices)
                        for device in cal_devices:
                            location.activatedAnchors[int(device)-1] = True
                    except Exception as ex:
                        print(ex)
                    
                    # read performance
                    try:
                        for i in range(8):
                            try:
                                rssi = int(section.get(f"d{i+1}_fp_pwr", 0))
                                #print(f"d{i+1}_fp_pwr", rssi)
                                location.performance[i].RSSI = rssi
                            except Exception as ex:
                                print(ex)

                            try:
                                snr = int(section.get(f"d{i+1}_edge_inx", 0))
                                #print(f"d{i+1}_edge_inx", snr)
                                location.performance[i].SNR = snr
                            except Exception as ex:
                                print(ex)
                            
                            try:
                                nev = int(section.get(f"d{i+1}_fp_inx", 0))
                                #print(f"d{i+1}_fp_inx", nev)
                                location.performance[i].NEV = nev
                            except Exception as ex:
                                print(ex)

                            try:
                                ner = int(section.get(f"d{i+1}_maxtapinx", 0))
                                #print(f"d{i+1}_maxtapinx", ner)
                                location.performance[i].NER = ner
                            except Exception as ex:
                                print(ex)

                            try:
                                per = int(section.get(f"d{i+1}_detect_pwr", 0))
                                #print(f"d{i+1}_detect_pwr", per)
                                location.performance[i].PER = per
                            except Exception as ex:
                                print(ex)
                    except Exception as ex:
                        print(ex)

                    # read zone
                    try:
                        zone = int(section.get("uwbZone", -1))
                        #print("detect_zone", zone)
                        location.zone = zone
                    except Exception as ex:
                        print(ex)
                    
                    # save location info
                    self.__locations[section_name] = location
                    self.locationsUpdated.emit()

                    # read one by one as requested !!!
                    break

        if self.__is_autoplay:
            # autoplay will go to next location
            self.show_next_location()
        else:
            self.currentLocationChanged.emit()
    
    def read_ble(self):
        self.__uwb_ble_info_file.read(UWB_BLE_INFO_FILE)

        if 'INFO' in self.__uwb_ble_info_file:
            ble = self.__uwb_ble_info_file['INFO']

            try:
                status = int(ble.get("status", 0))
                #print("read_ble", "status", status)
                self.__ble.status = status
            except Exception as ex:
                print(ex)

            try:
                rssi  = int(ble.get("rssi", -1000))
                #print("read_ble", "rssi", rssi )
                self.__ble.rssi  = rssi 
            except Exception as ex:
                print(ex)

            try:
                car_ctrl_cmd  = int(ble.get("car_ctrl_cmd", 0))
                #print("read_ble", "car_ctrl_cmd", car_ctrl_cmd )
                
                if car_ctrl_cmd == 1:
                    self.__ble.doorCount += 1
                elif car_ctrl_cmd == 4:
                    self.__ble.trunkCount += 1
                elif car_ctrl_cmd == 7:
                    self.__ble.engineCount += 1
            except Exception as ex:
                print(ex)

            self.bleUpdated.emit()

            # write car_ctrl_cmd = 0
            self.__uwb_ble_info_file['INFO']['car_ctrl_cmd'] = "0"

            with open(UWB_BLE_INFO_FILE, "w") as ble_file:
                self.__uwb_ble_info_file.write(ble_file)
            
    def update(self):
        self.read_log()
        self.read_ble()

    def get_car(self):
        ##print("get_car", self.__car)
        return self.__car

    def get_ble(self):
        ##print("get_ble", self.__ble)
        return self.__ble
    
    def get_params(self):
        ##print("get_params", self.__params)
        return self.__params

    def get_anchors(self):
        ##print("get_anchors", self.__anchors)
        return self.__anchors
    
    def get_locations(self):
        locations = []
        # convert dict to list
        for i in range(1,len(self.__locations)):
            location = self.__locations[f'loop {i}']
            locations.append(location)
        return locations

    def get_current_location(self):
        location = self.__locations[f'loop {self.__location_current_index}']
        ##print("get_current_location", location)
        return location
    
    def get_current_location_index(self):
        return self.__location_current_index
    
    def set_current_location_index(self, value):
        if value != self.__location_current_index:
            self.__location_current_index = value
            self.currentLocationChanged.emit()
    
    def get_total_locations(self):
        return len(self.__locations) - 1
    
    def get_autoplay_status(self):
        return self.__is_autoplay

    def set_autoplay_status(self, value):
        if value != self.__is_autoplay:
            self.__is_autoplay = value
            self.isAutoplayChanged.emit()
    
    def get_reading_log_status(self):
        return self.__is_reading_log

    def set_reading_log_status(self, value):
        if value != self.__is_reading_log:
            self.__is_reading_log = value
            self.isReadingLogChanged.emit()
    
    def get_ranging_status(self):
        return self.__is_ranging

    def set_ranging_status(self, value):
        if value != self.__is_ranging:
            self.__is_ranging = value
            self.isRangingChanged.emit()
    
    ### SLOTS
    @Slot()
    def save_car_location(self):
        self.__car.save_config()
    
    @Slot()
    def show_previous_location(self):
        if self.__location_current_index > 1:
            self.set_current_location_index(self.__location_current_index - 1)

    @Slot()
    def show_next_location(self):
        if self.__location_current_index < len(self.__locations) - 1:
            self.set_current_location_index(self.__location_current_index + 1)

    @Slot()
    def toggle_autoplay(self):
        self.set_autoplay_status(not self.__is_autoplay)
    
    @Slot()
    def toggle_reading_log(self):
        self.set_reading_log_status(not self.__is_reading_log)
    
    @Slot()
    def toggle_ranging(self):
        self.set_ranging_status(not self.__is_ranging)
        if self.__is_ranging:
            ### START RANGING ENGINE ###
            self.__ui_range.startRanging()
        else:
            ### STOP RANGING ENGINE ###
            self.__ui_range.stopRanging()
    
    ### PROPERTIES
    car = Property(Car, fget=get_car, notify=carUpdated)
    ble = Property(BLE, fget=get_ble, notify=bleUpdated)
    params = Property(Params, fget=get_params, notify=settingsUpdated)
    anchors = Property('QVariantList', fget=get_anchors, notify=settingsUpdated)
    locations = Property('QVariantList', fget=get_locations, notify=locationsUpdated)
    totalLocations = Property(int, fget=get_total_locations, notify=locationsUpdated)
    currentLocation = Property(Location, fget=get_current_location, notify=currentLocationChanged)
    currentLocationIndex = Property(int, fget=get_current_location_index, fset=set_current_location_index, notify=currentLocationChanged)

    isRanging = Property(bool, fget=get_ranging_status, notify=isRangingChanged)
    isReadingLog = Property(bool, fget=get_reading_log_status, notify=isReadingLogChanged)
    isAutoplay = Property(bool, fget=get_autoplay_status, fset=set_autoplay_status, notify=isAutoplayChanged)
