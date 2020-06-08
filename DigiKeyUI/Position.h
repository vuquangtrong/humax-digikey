#ifndef POSITION_H
#define POSITION_H

#include <QObject>

class Position: public QObject
{
    Q_OBJECT

    Q_PROPERTY(
            float x
            READ x
            NOTIFY updated)

    Q_PROPERTY(
            float y
            READ y
            NOTIFY updated)

    Q_PROPERTY(
            float z
            READ z
            NOTIFY updated)

public:
    Position(QObject* parent=nullptr) : QObject(parent) {}
    Position(Position& position){}
    Position& operator=(const Position&){}

    ~Position(){}
    float x(){return 0;}
    float y(){return 0;}
    float z(){return 0;}

signals:
    void updated();
};

#endif
