import sys
import os
import math
import time
import threading
import queue
import re
from glob import glob
from random import randint

from PySide2 import QtCore
from PySide2.QtCore import QObject, Property, Signal, Slot, QTimer
from PySide2.QtQml import qmlRegisterType

from configparser import ConfigParser
from ast import literal_eval
#from pygtail import Pygtail

from .location import Location
from .anchor import Anchor
from .params import Params
from .ble import BLE
from .performance import Performance
from .car import Car


###############################
# CHANGE BELOW LIB ON REAL HW #
###############################
#from ui_range_forTest2 import ui_range
from clsForUI import clsShareData #, clsForUI
from clsForUI_forTest import clsForUI # remove this line and use clsForUI in above line

###############################
# Read below log files
###############################
UWB_CONFIG_FILE= "log/uwbconfig.cfg"
UWB_LOCATION_LOG_FILE = "log/locating_data.txt"
UWB_BLE_INFO_FILE = "log/ble_info.txt"

FROM_LOG_FILE = 0
FROM_CLS_FOR_UI_QUEUE = 1
UPDATE_INTERVAL = 300 # ms
QUEUE_SIZE = 10000

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
        self.__uwb_ble_info_file = ConfigParser()
        #self.__uwb_location_log_file = ConfigParser()
        
        self.__car = Car()
        self.__ble = BLE()
        self.__params = Params()
        self.__anchors = [Anchor() for _ in range(8)] # A1 ~ A8
        self.__locations = []
        self.__location_current_index = -1

        self.__is_ranging = False
        self.__is_reading_log = False
        self.__is_autoplay = True

        # read configs
        self.read_config()

        # read log
        self.__update_timer = QTimer()
        self.__update_timer.timeout.connect(self.update)
        self.__update_timer.start(UPDATE_INTERVAL)
        
        self.__stop_event = threading.Event()
        self.__stop_event.set() # stop by default
        self.__reading_log_thread = None
        self.__new_location = None
        self.__time_start = None

        # read log from log file or from external queue?
        self.__location_queue = queue.Queue(QUEUE_SIZE)
        #self.__log_source = FROM_LOG_FILE
        self.__log_source = FROM_CLS_FOR_UI_QUEUE

        #self.__ui_range = ui_range()
        self.__clsForUI = clsForUI(ShareQueue=self.__location_queue, digikey_log=self)

        # remove last session
        try:
            for f in glob(r"log\*.offset"):
                os.remove(f)
        except OSError as _:
            pass

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
                    try:
                        self.__anchors[i].coordinate = location
                    except Exception as _:
                        pass  
                
                except Exception as _:
                    pass 
    
    # def read_log(self):
    #     # try to read the file, line by line
    #     while True:
    #         if self.__stop_event.is_set():
    #             return
            
    #         for line in Pygtail(UWB_LOCATION_LOG_FILE, every_n=10):
    #             if self.__stop_event.is_set():
    #                 return
                
    #             #time_start = time.time()
    #             #print(line)

    #             # find the start of a section
    #             if line.startswith("[loop"):
    #                 section_name = line.replace("[","").replace("]","").replace("\n","").replace("\r","")
    #                 if True:
    #                     self.__new_section_name = section_name
    #                     self.__new_location = Location()
    #                     self.__new_location.name = section_name
    #                     for anchor in self.__new_location.activatedAnchors:
    #                         anchor = False
                
    #             if self.__new_location:
    #                 # read location
    #                 if line.startswith("keylocation"):
    #                     try:
    #                         keylocation = literal_eval(line.replace("keylocation = ",""))
    #                         self.__new_location.coordinate = keylocation
    #                         #print("keylocation", keylocation)
    #                     except Exception as ex:
    #                         print(ex)

    #                     continue

    #                 # read distance
    #                 x = re.search(r"d(\d+)_distance = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = float(x.group(2))
    #                         #print(f"d{i}_distance =", d)
    #                         self.__new_location.distance[i-1] = -1.0 # 
    #                         if d >= 0 and d <= 20.0:
    #                             self.__new_location.distance[i-1] = d
    #                     except Exception as ex:
    #                         print(ex)

    #                     continue

    #                 # read activated anchors
                    
                    
    #                 if line.startswith("cal_devices"):
    #                     try:
    #                         cal_devices = literal_eval(line.replace("cal_devices = ",""))
    #                         #print("cal_devices", cal_devices)
    #                         for device in cal_devices:
    #                             self.__new_location.activatedAnchors[int(device)-1] = True
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue
                    
    #                 # read performance
    #                 x = re.search(r"d(\d+)_fp_pwr = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_fp_pwr =", d)
    #                         self.__new_location.performance[i-1].RSSI = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue
                    
    #                 x = re.search(r"d(\d+)_edge_inx = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_edge_inx =", d)
    #                         self.__new_location.performance[i-1].SNR = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue

    #                 x = re.search(r"d(\d+)_fp_inx = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_fp_inx =", d)
    #                         self.__new_location.performance[i-1].NEV = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue

    #                 x = re.search(r"d(\d+)_maxtapinx = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_maxtapinx =", d)
    #                         self.__new_location.performance[i-1].NER = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue

    #                 x = re.search(r"d(\d+)_detect_pwr = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_detect_pwr =", d)
    #                         self.__new_location.performance[i-1].PER = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue
                    
    #                 x = re.search(r"d(\d+)_maxtappwr = (.*)", line)
    #                 if x:
    #                     try:
    #                         i = int(x.group(1))
    #                         d = int(x.group(2))
    #                         #print(f"d{i}_maxtappwr =", d)
    #                         self.__new_location.performance[i-1].MPWR = d
    #                     except Exception as ex:
    #                         print(ex)
                        
    #                     continue
                    
    #                 if line.startswith("uwbzone"):
    #                     try:
    #                         uwbzone = int(line.replace("uwbzone = ",""))
    #                         self.__new_location.zone = uwbzone
    #                         #print("uwbzone", uwbzone)
    #                     except Exception as ex:
    #                         print(ex)

    #                     continue

    #                 # check the finish flag
    #                 if line.startswith("loopfinish = 1"):
    #                     # save location info
    #                     if not self.__location_queue.full():
    #                         self.__location_queue.put(self.__new_location)
    #                     self.__new_location = None

    #                     continue
                
    #             #time.sleep(0.1)
    #             #print(f"Reading took {time.time() - time_start} seconds")


    def retrieve_location(self):
        if not self.__location_queue.empty():
            #print("queue size", self.__location_queue.qsize())

            if not self.__stop_event.is_set():
                if self.__log_source == FROM_LOG_FILE:
                    # make a copy of location object because QMLEngine can not bind to cross-thread object
                    location = Location(origin=self.__location_queue.get())

                    if self.__time_start:
                        print(f"Reading {location.name} took {time.time() - self.__time_start} seconds")

                    self.__locations.append(location)
                    self.locationsUpdated.emit()

                    self.__time_start = time.time()
                else:
                    # convert from clsShareData to Location
                    
                    item = self.__location_queue.get()
                    #item.printAllData()

                    location = Location()
                    location.name = f"loop {item.loopCount}"

                    if self.__time_start:
                        print(f"Reading {location.name} took {time.time() - self.__time_start} seconds")

                    location.coordinate = [item.location_x, item.location_y, item.location_z]
                    location.distance = [item.dist_d1, item.dist_d2, item.dist_d3, item.dist_d4, item.dist_d5, item.dist_d6, item.dist_d7, item.dist_d8]
                    for anchor in item.activDevices:
                        location.activatedAnchors[int(anchor)-1] = True
                    for i in range(8):
                        location.performance[i].RSSI = item.fp_pwr[i]
                        location.performance[i].SNR = item.edge_inx[i]
                        location.performance[i].NEV = item.fp_inx[i]
                        location.performance[i].NER = item.max_inx[i]
                        location.performance[i].PER = item.detected_pwr[i]
                        location.performance[i].MPWR = item.max_pwr[i]
                    location.zone = item.uwbZone

                    self.__locations.append(location)
                    self.locationsUpdated.emit()

                    self.__time_start = time.time()

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
        self.read_ble()
        self.retrieve_location()
        if self.__is_autoplay:
            # autoplay will go to next location
            self.show_next_location()

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
        return self.__locations

    def get_current_location(self):
        location = None
        try:
            location = self.__locations[self.__location_current_index]
        except Exception as ex:
            print(ex)
        
        return location
    
    def get_current_location_index(self):
        return self.__location_current_index
    
    def set_current_location_index(self, value):
        if value != self.__location_current_index:
            self.__location_current_index = value
            self.currentLocationChanged.emit()
    
    def get_total_locations(self):
        return len(self.__locations)
    
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
    
    def get_ble_zone_status(self):
        return self.__ble.isShowingZone

    def set_ble_zone_status(self, value):
        if value != self.__ble.isShowingZone:
            self.__ble.isShowingZone = value
            self.bleUpdated.emit()
    
    ### SLOTS
    @Slot()
    def save_car_location(self):
        self.__car.save_config()
    
    @Slot()
    def save_ble_zone(self):
        self.__ble.save_config()
    
    @Slot()
    def show_previous_location(self):
        if self.__location_current_index > 0:
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
        if self.__is_reading_log:
            self.__stop_event.clear()
            # if self.__log_source == FROM_LOG_FILE:
            #     self.__reading_log_thread = threading.Thread(target=self.read_log, daemon=True)
            #     self.__reading_log_thread.start()
        else:
            self.__stop_event.set()
    
    @Slot()
    def toggle_ranging(self):
        self.set_ranging_status(not self.__is_ranging)
        if self.__is_ranging:
            ### START RANGING ENGINE ###
            #self.__ui_range.startRanging()
            self.__clsForUI.startRangingTask()
        else:
            ### STOP RANGING ENGINE ###
            #self.__ui_range.stopRanging()
            self.__clsForUI.stopRangingTask()

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
    isShowingBleZone = Property(bool, fget=get_ble_zone_status, fset=set_ble_zone_status, notify=bleUpdated)
