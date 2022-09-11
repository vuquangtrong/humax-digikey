# DigiKey
This project visualizes the data from DigiKey module on PC using pyQt UI

## Hardware

* NPX UWB (Ultra Wideband) Remote Control  
* CAN-USB interface

## Software

* Python 3  
* Qt QML (via PySide2 [Qt for Python](http://wiki.qt.io/Qt_for_Python))

1. Create a virtual environment if needed, 
2. Install [PySide2](https://pypi.org/project/PySide2/)

    ```
    pip install PySide2
    ```
3. Run the main file

    ```
    python PyDigiKey2.py
    ```

## Preview

![UI](UI.gif)

## License
This project comes with a GNU LGPL v3 license.  

## Notes
This repo only hold opensource files, which is under the QT open-source license. The core of ranging function is hidden because it is HUMAX's property. In this project, the ranger file is just an interface which returns fake data.
