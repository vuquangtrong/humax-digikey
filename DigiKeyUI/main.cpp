#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFont>
#include "Position.h"
#include "DigiKey.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

#if 0
    QFont appFont;
    appFont.setPointSize(12);
    QGuiApplication::setFont(appFont);
#endif

    QQmlApplicationEngine engine;

    qmlRegisterType<Position>("Position", 1, 0, "Position");
    engine.rootContext()->setContextProperty("DigiKey", new DigiKey());

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject *obj, const QUrl &objUrl) {if (!obj && url == objUrl) QCoreApplication::exit(-1);}, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
