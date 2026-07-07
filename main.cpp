#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QString>

// QGIS
#include <qgsapplication.h>

#include "GisProcessor.h"

int main(int argc, char *argv[])
{
    const QString osgeoRoot = QStringLiteral("D:/OSGeo4w");
    const QString qgisPrefix = osgeoRoot + QStringLiteral("/apps/qgis");
    const QString qgisPluginPath = qgisPrefix + QStringLiteral("/plugins");
    const QString qtPluginPath = QStringLiteral("D:/Qt/6.8.3/msvc2022_64/plugins");
    const QString gdalDataPath = osgeoRoot + QStringLiteral("/share/gdal");
    const QString projPath = osgeoRoot + QStringLiteral("/share/proj");

    qputenv("QGIS_PREFIX_PATH", qgisPrefix.toLocal8Bit());
    qputenv("QGIS_PLUGINPATH", qgisPluginPath.toLocal8Bit());
    qputenv("GDAL_DATA", gdalDataPath.toLocal8Bit());
    qputenv("PROJ_LIB", projPath.toLocal8Bit());
    qputenv("QT_PLUGIN_PATH", qtPluginPath.toLocal8Bit());

    QByteArray path = qgetenv("PATH");
    const QByteArray osgeoBin = QString(osgeoRoot + "/bin").toLocal8Bit();
    const QByteArray qgisBin = QString(qgisPrefix + "/bin").toLocal8Bit();
    const QByteArray qtBin = QStringLiteral("D:/Qt/6.8.3/msvc2022_64/bin").toLocal8Bit();

    if (!path.contains(osgeoBin)) {
        path.prepend(osgeoBin + ";");
    }
    if (!path.contains(qgisBin)) {
        path.prepend(qgisBin + ";");
    }
    if (!path.contains(qtBin)) {
        path.prepend(qtBin + ";");
    }
    qputenv("PATH", path);

    QgsApplication::setPrefixPath(qgisPrefix, true);

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
