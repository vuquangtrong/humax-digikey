#ifndef DIGIKEY_H
#define DIGIKEY_H

#include <QObject>
#include "Position.h"

class DigiKey: public QObject
{
    Q_OBJECT

    Q_PROPERTY(
            QString receiverStatus
            READ receiverStatus
            NOTIFY receiverStatusChanged
            )

    Q_PROPERTY (
            Position* position
            READ position
            NOTIFY positionUpdated
            )

public:
    DigiKey(QObject* parent=nullptr) : QObject(parent) {}
    QString receiverStatus(){return "Waiting...";}
    Position* position(){return &mPosition;}

signals:
    void receiverStatusChanged();
    void positionUpdated(QString msg);

private:
    Position mPosition;
};

#endif
