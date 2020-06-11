#from lib.can_serial import can_serial, wrapperCom
#from lib.LocFrmDist import LocFrmDist
import queue
import threading
import time

#import datetime

#import high_level_cmd as hlc
#from lib import ranger4, ranger4log, typeutils,s32k_commands,sequences, virtualio

class ui_range:
    def __init__(self):
        self.iteration = 10
        self.numOfAnchor = 8
        self.configID = 4
        self.channel_frequency = 6489600
        self.nominal_tx_power = 0
        self.sys_pll_mode = 0
        self.sync_code = 0
        self.location=[1,0,0, \
                2, 2, 2, \
                3, 3, 3, \
                4, 4, 4, \
                5, 1, 3, \
                6, 2, 4, \
                7, 3, 5, \
                8, 4, 6 ]
        self.locationQ = queue.Queue()

    def setIteration(self, iteration):
        self.iteration = iteration
        print(">>>>>>> set iteration", str(self.iteration))

    #locationList : (anchorId( 1 ~ 8 ) , x location , y location) * (4 ~ 8 )
    def setAnchorLocation(self, locationList):
        self.location = locationList
        print(">>>>>>> set Anchor location", str(self.location))

    # RX radio settings index to be used (0-7) it is supposed that TX radio setting index = RX index + 8
    # Carrier Frequecy for the UWB pulses (UWB Channel) values in KHz from 6400000 to 8000000, default: 6489600 (channel 5)
    # Transmission power in dBm ( allowed values from -12 to +14, default +0dBm)
    def setCfg(self, configID = 4, channel_frequency=6489600, nominal_tx_power=0, sys_pll_mode=0,sync_code=0):
        self.configID = configID
        self.channel_frequency = channel_frequency
        self.nominal_tx_power = nominal_tx_power
        self.sys_pll_mode = sys_pll_mode
        self.sync_code = sync_code
        print("### set configuration for signal")
        print(">>>>> configID", str(self.configID))
        print(">>>>> channel_frequency", str(self.channel_frequency))
        print(">>>>> nominal_tx_power", str(self.nominal_tx_power))


    # return x, y location as list
    def getLocation(self):
        count = 0
        while True:
            if self.locationQ.empty() is False:
                return self.locationQ.get()
            else:
                time.sleep(0.2)
                count = count + 1
                if count > 50:
                    return ["nodata", "nodata",0, 1, 2,3,4,1,2,3,4]
            time.sleep(0.2)


    def getAnchorPerformance(self, deviceId):
        performance = [1, 2, 3, 1, 2]
        performance[0] = performance[0] * deviceId
        performance[1] = performance[1] * deviceId
        performance[2] = performance[2] * deviceId
        performance[3] = performance[3] * deviceId
        performance[4] = performance[4] * deviceId
        return performance


    def startRanging(self):
        self.CanThread = threading.Thread(target=self.RangDistTask)
        self.CanThread.daemon = True
        self.CanThread.start()

    def stopRanging(self):
        print("Stop Ranging")

    def RangDistTask(self):
        location=[5,5,0,4,3,2,1,4,3,2,1 ]
        for inx in range(self.iteration):
            location[0] = location[0] + 0.1 * inx   # x 
            location[1] = location[1] - 0.1 * inx   # y
            location[2] = 0                         # z

            location[3] = 1 + 0.1 * inx #1
            location[4] = 2 + 0.1 * inx
            location[5] = 3 + 0.1 * inx
            location[6] = 4 + 0.1 * inx
            location[7] = 1 - 0.1 * inx#5
            location[8] = 2 - 0.1 * inx
            location[9] = 3 - 0.1 * inx
            location[10] = 4 - 0.1 * inx

            self.locationQ.put(location)
            time.sleep(0.5)


