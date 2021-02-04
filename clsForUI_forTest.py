import random
import threading
import queue
import time

from clsForUI import clsShareData

"""
Dummy implementation for testing UI
"""
class clsForUI:
    def __init__(self, ShareQueue = None, digikey_log = None):
        print("ShareQueue", ShareQueue)
        print("digikey_log", digikey_log)

        self.__queue = ShareQueue
        self.__digikey_log = digikey_log
        self.__stop_event = threading.Event()
        self.__stop_event.set() # stop by default
        self.__report_thread = None

    def startRangingTask(self):
        print("Start Ranging")
        self.__stop_event.clear()
        self.__report_thread = threading.Thread(target=self.report, daemon=True)
        self.__report_thread.start()

    def stopRangingTask(self):
        print("Stop Ranging")
        self.__stop_event.set()
    
    def report(self):
        # create a fake location report
        loop_count = 0
        while True:
            if self.__stop_event.is_set():
                break
            
            loop_count += 1

            # start a loop
            location = clsShareData()

            location.setLoopCount(loop_count)
            # transfer location instance to the engine to fill data
            # set target devices
            # execute command
            time.sleep(0.3) # execution time
            # inside engine, it set data
            location.setLocation(random.uniform(-5,5), random.uniform(-5,5), random.uniform(-5,5))
            for i in range(8):
                location.setDistance(f"d{i}", random.uniform(-5,5))
                # create a list of active anchors
                a = [i for i in range(8) if random.randint(0,1)==1]
                location.setActiveDevices(a)
                location.setRfInfo(f"d{i}", 
                    random.randint(0,100),
                    random.randint(0,100),
                    random.randint(0,100),
                    random.randint(0,100),
                    random.randint(0,100),
                    random.randint(0,100))
                location.setUwbZone(random.randint(0,8))
            
            # finally, put it to queue
            #location.printAllData()
            if self.__queue and not self.__queue.full():
                self.__queue.put(location)
