from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from configparser import ConfigParser
from ast import literal_eval
from datetime import datetime
import math

from model.repeat_timer import RepeatTimer
from model.position import Position
from model.anchor import Anchor
from model.params import Params

###############################
# CHANGE BELOW LIB ON REAL HW #
###############################
from ui_range_forTest import ui_range

###############################
# read below log files
UWB_Configs_File = "log\\uwbconfig.cfg"
UWB_Locations_File = "log\\locating_data.txt"
###############################

UWB_READ_LOG_INTERVAL = 0.3
ITERATION_HISTORY = 200

class DigiKeyFromLog(QObject):
    paramsUpdated = Signal()
    positionUpdated = Signal(int)
    position2Updated = Signal(int)
    anchorsUpdated = Signal()
    zoneUpdated = Signal()
    appStatusUpdated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._params = Params(file=None)
        self._params.updated.connect(self.on_params_updated)

        self._position = Position()
        self._position_history = [[] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[] for _ in range(len(self._position.distance))]

        self._position2 = Position()
        self._position_history2 = [[] for _ in range(len(self._position.coordinate))]

        self._anchors = [Anchor() for _ in range(8)]

        self._activated_zone = 0

        self._started = False
        self._debuggable = False
        self._use_2nd_calc = False

        self._ui_range = ui_range()

        self._update_timer = None

        self._UWB_configs = ConfigParser()   
        self._UWB_locations = ConfigParser()
        self._shown_sections = 1

    def __del__(self):
        self.deinit()

    def deinit(self):
        if self._update_timer.is_alive():
            self._update_timer.cancel()

    def whoami(self):
        return datetime.now().strftime("%H:%M:%S") + " LOG "

    def on_params_updated(self):
        self._params.save()
        self.paramsUpdated.emit()

    def get_params(self):
        return self._params

    def get_position(self):
        return self._position

    def get_position2(self):
        return self._position2

    def get_position_history(self):
        return self._position_history

    def get_position_history2(self):
        return self._position_history2

    def get_distance_history(self):
        return self._distance_history

    def get_anchors(self):
        return self._anchors

    def get_activated_zone(self):
        return self._activated_zone

    def get_started(self):
        return self._started

    def set_started(self, value):
        if self._started != value:
            self._started = value
            self.appStatusUpdated.emit()

    def get_debuggable(self):
        return self._debuggable

    def set_debuggable(self, value):
        if self._debuggable != value:
            self._debuggable = value
            self.appStatusUpdated.emit()

    def get_use_2nd_calc(self):
        return self._use_2nd_calc

    def set_use_2nd_calc(self, value):
        if self._use_2nd_calc != value:
            self._use_2nd_calc = value
            self.appStatusUpdated.emit()

    def parse_configs(self):
        self._UWB_configs.read(UWB_Configs_File)
        if 'uwb config' in self._UWB_configs:
            params = self._UWB_configs['uwb config']

            try:
                n = int(params.get('intervaltime_ranging', 800))
                print(self.whoami() + "intervaltime_ranging", n)
                self._params.N = 0 if math.isnan(n) else n
            except Exception as _:
                pass

            try:
                f = int(params.get('frequency', 6489600))
                print(self.whoami() + "frequency", f)
                self._params.F = 6489600 if math.isnan(f) else f
            except Exception as _:
                pass

            try:
                r = int(params.get('rxcfgindex', 2))
                print(self.whoami() + "rxcfgindex", r)
                self._params.R = 3 if math.isnan(r) else r
            except Exception as _:
                pass
            
            try:
                #p = int(params.get('powermode', 0))
                p = int(params.get('txpower', 0))
                print(self.whoami() + "txpower", p)
                self._params.P = 0 if math.isnan(p) else p
            except Exception as _:
                pass
            
        if 'config on host' in self._UWB_configs:
            configs = self._UWB_configs['config on host']

            # clear anchor settings
            for i in range(8):
                for j in range(4):
                    self._params.set_anchor(i, j, 0)
            
            try:
                anchors = str.split(configs.get('workingdeviceids', ''), ',')
                print(self.whoami() + "workingdeviceids", anchors)
                for anchor in anchors:
                    self._params.set_anchor(int(anchor)-1, 3, 1)        
            except Exception as _:
                pass
        
        if 'locating' in self._UWB_configs:
            anchors = self._UWB_configs['locating']
            for i in range(8):
                try:
                    location = literal_eval(anchors.get(f"d{i+1}_location", "[0,0,0]"))
                    print(self.whoami() + f"anchor {i+1} at", location)
                    for j in range(3):
                        try:
                            self._params.set_anchor(i, j, location[j]) 
                        except Exception as _:
                            pass         
                except Exception as _:
                    pass 

        self.paramsUpdated.emit()

    def parse_location_section(self, section_name):
        print(section_name)
        section = self._UWB_locations[section_name]
        position_status = 0
        position_status2 = 0
        try:
            # read location
            location_data = literal_eval(section.get("keylocation", "[0,0,0]"))
            print(self.whoami() + "got location", location_data)
            try:
                for i in range(3):
                    position_status = 0
                    try:
                        self._position.coordinate[i] = float(location_data[i])
                        if len(self._position_history[i]) > ITERATION_HISTORY:
                            self._position_history[i].pop(0)
                        self._position_history[i].append(self._position.coordinate[i])
                        position_status = 1
                    except Exception as ex:
                        print(ex)
                print(self.whoami() + "added position", len(self._position_history[0]), 'to history')
            except Exception as ex:
                print(ex)

            if location_data[0] == 'nodata':
                position_status = -1
            if location_data[0] == 'wrong':
                position_status = -2

            # read distance
            try:
                for i in range(8):
                    d = float(section.get(f"d{i+1}_distance", 0))
                    print(self.whoami() + f"d{i+1}_distance =", d)
                    if d < 1000.0:
                        try:
                            self._position.distance[i] = float(d)
                        except Exception as ex:
                            self._position.distance[i] = -1
                            print(ex)
                    else:
                        self._position.distance[i] = -1
                for i in range(8):
                    if len(self._distance_history[i]) > ITERATION_HISTORY:
                        self._distance_history[i].pop(0)
                    self._distance_history[i].append(self._position.distance[i])
            except Exception as ex:
                print(ex)
            
            # read activated anchors
            for anchor in self._anchors:
                anchor.active = False
            cal_devices = literal_eval(section.get("cal_devices", "[]"))
            print(self.whoami() + "got cal_devices", cal_devices)
            try:
                for i in range(3):
                    a = cal_devices[i]
                    try:
                        self._anchors[int(a)-1].active = True
                    except Exception as ex:
                        print(ex)
            except Exception as ex:
                print(ex)
        except Exception as _:
            pass  
        
        if self._use_2nd_calc:
            pass

        if self._debuggable:
            pass
            # get performance
            for i in range(len(self._anchors)):
                try:
                    overall_pwr = float(section.get(f"d{i+1}_overall_pwr", 0))
                    print(self.whoami() + f"d{i+1}_overall_pwr", overall_pwr)
                    self._anchors[i].RSSI = overall_pwr
                    self._anchors[i].SNR = 0
                    self._anchors[i].NEV = 0
                    self._anchors[i].NER = 0
                    self._anchors[i].PER = 0
                except Exception as ex:
                    print(ex)
        
        # get activated zone
        self._activated_zone = 0
        try:
            self._activated_zone = 0
            print(self.whoami() + "got activated zone", self._activated_zone)
        except Exception as ex:
            print(ex)

        # notify
        self.positionUpdated.emit(position_status)
        self.position2Updated.emit(position_status2)
        self.anchorsUpdated.emit()
        self.zoneUpdated.emit()

    def update_ui(self):
        self.update_position()

    def update_position(self):
        print(self.whoami() + "READING FROM FILE")
        self._UWB_locations.read(UWB_Locations_File)
        #print(self.whoami() + "total sections:", len(self._UWB_locations.sections()))
        #print(self.whoami() + "looking for", self._shown_sections)
        
        if f'loop {self._shown_sections}' in self._UWB_locations.sections():
            print(self.whoami() + "found", self._shown_sections)
            self.parse_location_section(f'loop {self._shown_sections}')
            self._shown_sections += 1

    params = Property(Params, fget=get_params, notify=paramsUpdated)

    position = Property(Position, fget=get_position, notify=positionUpdated)
    positionHistory = Property("QVariantList", fget=get_position_history, notify=positionUpdated)
    distanceHistory = Property("QVariantList", fget=get_distance_history, notify=positionUpdated)

    position2 = Property(Position, fget=get_position2, notify=position2Updated)
    positionHistory2 = Property("QVariantList", fget=get_position_history2, notify=position2Updated)

    anchors = Property("QVariantList", fget=get_anchors, notify=anchorsUpdated)

    activatedZone = Property(int, fget=get_activated_zone, notify=zoneUpdated)

    started = Property(bool, fget=get_started, notify=appStatusUpdated)
    debuggable = Property(bool, fget=get_debuggable, fset=set_debuggable, notify=appStatusUpdated)
    use2ndCalc = Property(bool, fget=get_use_2nd_calc, fset=set_use_2nd_calc, notify=appStatusUpdated)

    @Slot()
    def activate(self):
        print(self.whoami() + "Activate")
        self.parse_configs()
    
    @Slot()
    def request_start(self):
        if not self._started:
            print(self.whoami() + "Start")
            try:
                ### START RANING HERE ###
                self._ui_range.startRanging()
                self.set_started(True)
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Start failed!!!\n" + str(ex))
                popup.exec_()
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "Ranging is already started")
            popup.exec_()

    @Slot(bool)
    def request_read_log(self, reading = False):
        if reading == False:
            try:
                self._update_timer = RepeatTimer(UWB_READ_LOG_INTERVAL, self.update_ui)
                self._update_timer.daemon = True
                self._update_timer.start()
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Cannot start reading log files!!!\n" + str(ex))
                popup.exec_()
        else:
            try:
                self._update_timer.cancel()
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Cannot stop reading log files!!!\n" + str(ex))
                popup.exec_()

    @Slot()
    def request_clear_ui(self):
        self._shown_sections = 1
        self.request_clear_history(inited=False)

    @Slot()
    def request_stop(self):
        if self._started:
            print(self.whoami() + "Stop")
            try:
                self._ui_range.stopRanging()
                self.set_started(False)
            except Exception as ex:
                print(ex)
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "This session is not running")
            popup.exec_()

    @Slot(bool)
    def request_clear_history(self, inited=True):
        print(self.whoami() + "Clear history")
        self._position_history = [[] for _ in range(len(self._position.coordinate))]
        self._distance_history = [[] for _ in range(len(self._position.distance))]
        if inited:
            self.positionUpdated.emit(0)

        self._position_history2 = [[] for _ in range(len(self._position.coordinate))]
        if inited:
            self.position2Updated.emit(0)
