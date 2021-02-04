class clsShareData:
    def __init__(self, loopCount = 0
                       , dist_d1 = 0,  dist_d2 = 0, dist_d3 = 0
                       , dist_d4 = 0, dist_d5 = 0, dist_d6 = 0
                       , dist_d7 = 0, dist_d8 = 0
                       , fp_inx = 0, fp_pwr = 0
                       , max_inx = 0, max_pwr = 0
                       , detected_pwr = 0, edge_inx = 0
                       , activeDevices = [1,2,3]
                       , location_x = 0, location_y = 0, location_z = 0
                       , uwbZone = 0
                       ):
        self.loopCount = loopCount
        self.dist_d1 = dist_d1
        self.dist_d2 = dist_d2
        self.dist_d3 = dist_d3
        self.dist_d4 = dist_d4
        self.dist_d5 = dist_d5
        self.dist_d6 = dist_d6
        self.dist_d7 = dist_d7
        self.dist_d8 = dist_d8

        self.activDevices = activeDevices

        self.fp_inx = [0,0,0,0,0,0,0,0] 
        self.fp_pwr = [0,0,0,0,0,0,0,0] 
        self.max_inx = [0,0,0,0,0,0,0,0] 
        self.max_pwr = [0,0,0,0,0,0,0,0]
        self.detected_pwr = [0,0,0,0,0,0,0,0]
        self.edge_inx = [0,0,0,0,0,0,0,0]

        for inx in range(8):
            self.fp_inx[inx] = fp_inx
            self.fp_pwr[inx] = fp_pwr
            self.max_inx[inx] = max_inx
            self.max_pwr[inx] = max_pwr
            self.detected_pwr[inx] = detected_pwr
            self.edge_inx[inx]  = edge_inx

        self.location_x = location_x
        self.location_y = location_y
        self.location_z = location_z

        self.uwbZone  = uwbZone

    #def setDistance(self, dist_d1 = 0,  dist_d2 = 0, dist_d3 = 0
    #                   , dist_d4 = 0, dist_d5 = 0, dist_d6 = 0
    #                   , dist_d7 = 0, dist_d8 = 0):
    def setDistance(self, deviceId = 0,  distance = 0 ):

        deviceId = deviceId.lstrip('d') 
        deviceId = int(deviceId)
        if deviceId == 1:
            self.dist_d1 = distance
        elif deviceId == 2:
            self.dist_d2 = distance
        elif deviceId == 3:
            self.dist_d3 = distance
        elif deviceId == 4:
            self.dist_d4 = distance
        elif deviceId == 5:
            self.dist_d5 = distance
        elif deviceId == 6:
            self.dist_d6 = distance
        elif deviceId == 7:
            self.dist_d7 = distance
        elif deviceId == 8:
            self.dist_d8 = distance

    def setLocation (self, location_x =0, location_y =0, location_z =0 ):
        self.location_x = location_x
        self.location_y = location_y
        self.location_z = location_z

    def setRfInfo ( self ,deviceId = 'd1', fp_inx = 0, fp_pwr = 0
                       , max_inx = 0, max_pwr = 0
                       , detected_pwr = 0, edge_inx = 0):
        deviceId = deviceId.lstrip('d') 
        deviceId = int(deviceId)
        self.fp_inx[deviceId - 1] = fp_inx
        self.fp_pwr[deviceId - 1]  = fp_pwr
        self.max_inx[deviceId - 1]  = max_inx
        self.max_pwr[deviceId - 1]  = max_pwr
        self.detected_pwr[deviceId - 1]  = detected_pwr
        self.edge_inx[deviceId - 1]   = edge_inx

    def setActiveDevices(self, activeDevices=[1,2,3]):
        self.activDevices = activeDevices
        #print(f'activeDevices: {self.activDevices}')

    def setUwbZone ( self, uwbZone = 0):
        self.uwbZone = uwbZone

    def setLoopCount ( self, loopCount = 0):
        self.loopCount = loopCount

    def printAllData(self):
        print(f'loopCount - {self.loopCount}')
        print(f'dist_d1 - {self.dist_d1}')
        print(f'dist_d2 - {self.dist_d2}')
        print(f'dist_d3 - {self.dist_d3}')
        print(f'dist_d4 - {self.dist_d4}')
        print(f'dist_d5 - {self.dist_d5}')
        print(f'dist_d6 - {self.dist_d6}')
        print(f'dist_d7 - {self.dist_d7}')
        print(f'dist_d8 - {self.dist_d8}')

        print(f'activeDevices - {self.activDevices}')

        print(f'fp_inx - {self.fp_inx}')
        print(f'fp_pwr - {self.fp_pwr}')
        print(f'max_inx - {self.max_inx}')
        print(f'max_pwr - {self.max_pwr}')
        print(f'detected_pwr - {self.detected_pwr}')
        print(f'edge_inx - {self.edge_inx}')


        print(f'location_x - {self.location_x}')
        print(f'location_y - {self.location_y}')
        print(f'location_z - {self.location_z}')

        print(f'uwbZone - {self.uwbZone}')


"""
class clsForUI:
    def __init__(self, ShareQueue = None, digikey_log = None):
        pass

    def startRangingTask(self):
        pass

    def stopRangingTask(self):
        pass

class clsForUI:
    def __init__(self, ShareQueue = None, digikey_log = None):
        self._stop_event = threading.Event()
        self.digikey_log = digikey_log
        self.canDevice = canDevice(False, True, digikey_log=digikey_log)
        self.configControl = configControl()
        self.recordEngine = recordEngineForLocating(fileName='log/locating_data.txt', bNewFile = True, digikey_log = self.digikey_log)
        self.recordEngine.setLoopCount(1)

    def _RangingTask(self):
        #o_locating = locating(self.recordEngine, locatingAlgorithm.ALGORITHM_SIMPLE)
        o_locating = locating(self.recordEngine, locatingAlgorithm.ALGORITHM_3D)
        o_reportEngine = reportEngineForLocating(recordEngine = self.recordEngine , configControl = self.configControl)

        o_ranging = ranging(configControl = self.configControl, mCanDevice = self.canDevice, recEngine = self.recordEngine, locating = o_locating, reportEngine = o_reportEngine, digikey_log = self.digikey_log)   # need recordengineForLocating  and working devices as list like [ 1,2,3 ]
        o_ranging.configForRanging()                            # RCI commnads for configurating Ranging 
        
        m_bLocating = False
        if (len(self.configControl.getWorkingDevices()) > 2):
            m_bLocating = True
        o_ranging.startRanging(bRfInfo=True, bReporting=False , bLocating = m_bLocating, isStopped = self._stop_event, bBatchRun = True  )



    def startRangingTask(self):
        self.RangingTask = threading.Thread( target=self._RangingTask)
        self.RangingTask.daemon = True   
        self._stop_event.clear()
        self.RangingTask.start()

    def stopRangingTask(self):
        self._stop_event.set()


if __name__ == '__main__':
    o_sharedQueue  = queue.Queue()

    o_API_forUI = clsForUI(ShareQueue = o_sharedQueue, digikey_log = None)
    o_API_forUI.startRangingTask()
    try:
        while True:
            time.sleep(5)
            print(o_sharedQueue)
    except KeyboardInterrupt:
        print("Stopped by Keyboard Interrupt")

"""