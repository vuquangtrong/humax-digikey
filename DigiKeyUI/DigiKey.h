#ifndef DIGIKEY_H
#define DIGIKEY_H

#include <QObject>
#include <QVariantList>
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

    Q_PROPERTY (
            QVariantList positionHistory
            READ positionHistory
            NOTIFY positionUpdated
            )

    Q_PROPERTY (
            QVariantList distanceHistory
            READ distanceHistory
            NOTIFY positionUpdated
            )

public:
    DigiKey(QObject* parent=nullptr) : QObject(parent) {}
    QString receiverStatus(){return "Waiting...";}
    Position* position(){return &mPosition;}
    QVariantList positionHistory(){return mPositionHistory;}
    QVariantList distanceHistory(){return mDistanceHistory;}


signals:
    void receiverStatusChanged();
    void positionUpdated(QString msg);

private:
    Position mPosition;
    QVariantList mPositionHistory;
    QVariantList mDistanceHistory;
};

#endif
