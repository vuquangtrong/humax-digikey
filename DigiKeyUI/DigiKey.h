#ifndef DIGIKEY_H
#define DIGIKEY_H

#include <QObject>
#include <QVariantList>
#include "Position.h"

class DigiKey: public QObject
{
    Q_OBJECT

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

    Q_PROPERTY(
            QVariantList anchors
            READ anchors
            NOTIFY anchorUpdated
            )
public:
    DigiKey(QObject* parent=nullptr) : QObject(parent) {}
    QString receiverStatus(){return "Waiting...";}
    Position* position(){return &mPosition;}
    QVariantList positionHistory(){return mPositionHistory;}
    QVariantList distanceHistory(){return mDistanceHistory;}
    QVariantList anchors(){return mAnchors;}

signals:
    void receiverStatusChanged();
    void positionUpdated(Position*);
    void anchorUpdated(QVariantList);

private:
    Position mPosition;
    QVariantList mPositionHistory;
    QVariantList mDistanceHistory;
    QVariantList mAnchors;
};

#endif
