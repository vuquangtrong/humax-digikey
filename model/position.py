from PySide2 import QtCore
from PySide2.QtCore import QObject, Slot, Signal, Property
from PySide2.QtWidgets import QApplication, QMessageBox
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

# Position holds the coordinate value and distances to anchors
class Position(QObject):
    updated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._coordinate = [0.0] * 3  # x, y, z
        self._distance = [0.0] * 8  # D1 ~ D8

    def get_coordinate(self):
        return self._coordinate

    def set_coordinate(self, value):
        if self._coordinate != value:
            self._coordinate = value
            self.updated.emit()

    def get_distance(self):
        return self._distance

    def set_distance(self, value):
        if self._distance != value:
            self._distance = value
            self.updated.emit()

    # PySide2 does not natively convert python list to QVariantList, must use it explicitly
    coordinate = Property("QVariantList", fget=get_coordinate, fset=set_coordinate, notify=updated)
    distance = Property("QVariantList", fget=get_distance, fset=set_distance, notify=updated)
