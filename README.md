# PyDigiKey
This project visualizes the data from DigiKey in Qt-based UI

### Hardware
NPX UWB (Ultra Wideband) Remote Control  
CAN-USB interface

### Software
Python 3  
Qt QML (via PySide2 [Qt for Python](http://wiki.qt.io/Qt_for_Python))

create a virtual environment if needed, 
then install [PySide2](https://pypi.org/project/PySide2/)
```
pip install PySide2
```

### Preview
![UI](UI.gif)

## License
This project comes with a GNU LGPL v3 license.  

## Notes
This repo only hold opensource files, which is under the QT open-source license. The core of ranging function is hidden due to a copyright license. In this project, the ranger file is just an interface which returns fake data.
