#ifndef POSITION_H
#define POSITION_H

#include <QObject>
#include <QVariant>

class Position: public QObject
{
    Q_OBJECT

    Q_PROPERTY(
            QVariantList coordinate
            READ coordinate
            NOTIFY updated)

    Q_PROPERTY(
            QVariantList distance
            READ distance
            NOTIFY updated)

public:
    explicit Position(QObject* parent=nullptr) : QObject(parent) {}
    QVariantList coordinate(){return mCoordinate;}
    QVariantList distance(){return mDistance;}

signals:
    void updated();

private:
    QVariantList mCoordinate;
    QVariantList mDistance;
};

#endif
