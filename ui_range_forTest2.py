import os
import threading
import time
import random 
from configparser import ConfigParser

LOG_FILE = "log/locating_data.txt"
SAMPLE_LOG_FILE = "log/sample_location.txt"


class ui_range:
    def __init__(self):
        self.__stop_event = threading.Event()
        self.__stop_event.clear()

        self.__report_thread = None
        self.__sample_data = ConfigParser()
        self.__sample_data.read(SAMPLE_LOG_FILE)
        self.__sample_items = self.__sample_data.items("loop 0")

        self.__log_data = ConfigParser()
        self.__log_count = 0

        # open and delete its content
        self.__config_file = open(LOG_FILE, "w")
    
    def startRanging(self):
        print("Start Ranging")
        # start new thread for writing to file
        self.__stop_event.clear()
        self.__report_thread = threading.Thread(target=self.report, daemon=True)
        self.__report_thread.start()

    def stopRanging(self):
        print("Stop Ranging")
        self.__stop_event.set()

    def make_section(self):
        # add new section
        self.__log_count += 1
        section  = f"loop {self.__log_count}"
        self.__log_data.add_section(section)

        # add items to new section
        for item in self.__sample_items:
            self.__log_data.set(section, item[0], item[1])

        # modify some of them
        self.__log_data[section]['keylocation'] = str([random.uniform(-5, 5), random.uniform(-5, 5), 0])

    def report(self):
        while not self.__stop_event.is_set():
            time_start = time.time()
            time.sleep(0.3)
            self.make_section()
            self.__log_data.write(self.__config_file)
            print(f"Reporting {self.__log_count}: took {time.time() - time_start} seconds")
