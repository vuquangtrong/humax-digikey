from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from datetime import datetime

from model.repeat_timer import RepeatTimer
from model.position import Position
from model.anchor import Anchor
from model.params import Params

###############################
# CHANGE BELOW LIB ON REAL HW #
###############################
from ui_range_forTest import ui_range

UWB_READ_INTERVAL = 0.3
ITERATION_HISTORY = 200

# DigiKeyFromDevice reads from ui_range
class DigiKeyFromDevice(QObject):
    paramsUpdated = Signal()
    positionUpdated = Signal(int)
    position2Updated = Signal(int)
    anchorsUpdated = Signal()
    zoneUpdated = Signal()
    appStatusUpdated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._params = Params()
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

        self._update_timer = RepeatTimer(UWB_READ_INTERVAL, self.update_ui)
        self._update_timer.daemon = True
        self._update_timer.start()

    def __del__(self):
        self.deinit()

    def deinit(self):
        if self._update_timer.is_alive():
            self._update_timer.cancel()

    def whoami(self):
        return datetime.now().strftime("%H:%M:%S") + "DEVICE "
    
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

    def update_ui(self):
        self.update_position()

    def update_position(self):
        if self._started:
            # get location
            position_status = 0
            position_status2 = 0

            try:
                location_data = self._ui_range.getLocation()
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

                # read distances
                try:
                    for i in range(8):
                        d = location_data[3+i]
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

                try:
                    for i in range(3):
                        a = location_data[3+8+i]
                        try:
                            self._anchors[int(a)-1].active = True
                        except Exception as ex:
                            print(ex)
                except Exception as ex:
                    print(ex)
            except Exception as ex:
                print(ex)

            if self._use_2nd_calc:
                try:
                    location_data2 = self._ui_range.getLocation_addition()
                    print(self.whoami() + "got additional location", location_data2)
                    try:
                        for i in range(3):
                            position_status2 = 0
                            try:
                                self._position2.coordinate[i] = float(location_data2[i])
                                if len(self._position_history2[i]) > ITERATION_HISTORY:
                                    self._position_history2[i].pop(0)
                                self._position_history2[i].append(self._position2.coordinate[i])
                                position_status2 = 1
                            except Exception as ex:
                                print(ex)
                    except Exception as ex:
                        print(ex)

                    if location_data2[0] == 'nodata':
                        position_status2 = -1
                    if location_data2[0] == 'wrong':
                        position_status2 = -2
                except Exception as ex:
                    print(ex)

            if self._debuggable:
                # get performance
                for i in range(len(self._anchors)):
                    try:
                        performance = self._ui_range.getAnchorPerformance(i)
                        print(self.whoami() + "got anchor performance", performance)
                        self._anchors[i].RSSI = float(performance[0])
                        self._anchors[i].SNR = float(performance[1])
                        self._anchors[i].NEV = float(performance[2])
                        self._anchors[i].NER = float(performance[3])
                        self._anchors[i].PER = float(performance[4])
                    except Exception as ex:
                        print(ex)

            # get activated zone
            self._activated_zone = 0
            try:
                self._activated_zone = int(self._ui_range.detectZone())
                print(self.whoami() + "got activated zone", self._activated_zone)
            except Exception as ex:
                print(ex)

            # notify
            self.positionUpdated.emit(position_status)
            self.position2Updated.emit(position_status2)
            self.anchorsUpdated.emit()
            self.zoneUpdated.emit()

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
        self.paramsUpdated.emit()
    
    @Slot()
    def request_start(self):
        if not self._started:
            print(self.whoami() + "Start")
            try:
                self._ui_range.setIteration(self._params.N)
                anchors_location = []
                for anchor in self._params.anchors:
                    for x in anchor:
                        anchors_location.append(x)
                self._ui_range.setAnchorLocation(anchors_location)
                self._ui_range.setCfg(configID=self._params.R, channel_frequency=self._params.F, nominal_tx_power=self._params.P)
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Init failed!!!\n" + str(ex))
                popup.exec_()

            try:
                self._ui_range.startRanging()
                self.set_started(True)
                self.request_clear_history(inited=False)
            except Exception as ex:
                popup = QMessageBox(QMessageBox.Critical, "Critical", "Start failed!!!\n" + str(ex))
                popup.exec_()
        else:
            popup = QMessageBox(QMessageBox.Warning, "Warning", "Ranging is already started")
            popup.exec_()
    
    @Slot()
    def request_read_log(self):
        print(self.whoami() + "<Not implemented> Read Log")

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
            popup = QMessageBox(QMessageBox.Warning, "Warning", "Ranging is not running")
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
