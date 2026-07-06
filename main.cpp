#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

// QGIS
#include <qgsapplication.h>

#include "GisProcessor.h"

int main(int argc, char *argv[])
{
    // QgsApplication must be used instead of QGuiApplication so that
    // QGIS providers, projections and other subsystems are initialised correctly.
    QgsApplication app(argc, argv, /*GUIenabled=*/true);

    // Initialise QGIS (loads providers, PROJ data, etc.)
    QgsApplication::initQgis();

    // -----------------------------------------------------------------------
    // QML engine
    // -----------------------------------------------------------------------
    QQmlApplicationEngine engine;

    // Register the backend as a context property so QML can call it by name.
    GisProcessor gisProcessor;
    engine.rootContext()->setContextProperty(QStringLiteral("gisProcessor"),
                                             &gisProcessor);

    // Load the main QML file
    const QUrl url(QStringLiteral("qrc:/MDMProyectosMovil/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );
    engine.load(url);

    const int exitCode = app.exec();

    // Clean up QGIS subsystems (providers, PROJ, etc.)
    QgsApplication::exitQgis();

    return exitCode;
}
