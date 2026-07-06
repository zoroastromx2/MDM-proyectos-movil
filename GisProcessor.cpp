#include "GisProcessor.h"

#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QUrl>

// QGIS headers
#include <qgsapplication.h>
#include <qgsvectorlayer.h>
#include <qgsvectorfilewriter.h>
#include <qgsproject.h>
#include <qgscoordinatereferencesystem.h>
#include <qgscoordinatetransformcontext.h>
#include <qgsproviderregistry.h>

// ---------------------------------------------------------------------------
// Helper: convert a QML URL string (file:///…) or plain path to a local path
// ---------------------------------------------------------------------------
static QString urlToLocalPath(const QString &urlOrPath)
{
    if (urlOrPath.startsWith(QLatin1String("file:///"))) {
        return QUrl(urlOrPath).toLocalFile();
    }
    if (urlOrPath.startsWith(QLatin1String("file://"))) {
        return QUrl(urlOrPath).toLocalFile();
    }
    return urlOrPath;
}

// ---------------------------------------------------------------------------
GisProcessor::GisProcessor(QObject *parent)
    : QObject(parent)
{}

// ---------------------------------------------------------------------------
void GisProcessor::processDirectory(const QString &shapeDirUrl,
                                    const QString &styleDirUrl)
{
    emit processingStarted();

    // ------------------------------------------------------------------
    // 1. Resolve directory paths
    // ------------------------------------------------------------------
    const QString shapeDir = urlToLocalPath(shapeDirUrl);
    const QString styleDir = urlToLocalPath(styleDirUrl);

    QDir inputDir(shapeDir);
    if (!inputDir.exists()) {
        emit processingFinished(false,
            tr("El directorio de shapefiles no existe: %1").arg(shapeDir));
        return;
    }

    // ------------------------------------------------------------------
    // 2. Collect .shp files
    // ------------------------------------------------------------------
    const QStringList shpFiles = inputDir.entryList(QStringList() << QStringLiteral("*.shp"),
                                                     QDir::Files, QDir::Name);
    if (shpFiles.isEmpty()) {
        emit processingFinished(false,
            tr("No se encontraron archivos .shp en: %1").arg(shapeDir));
        return;
    }

    // ------------------------------------------------------------------
    // 3. Determine output paths
    // ------------------------------------------------------------------
    const QString gpkgPath  = inputDir.filePath(QStringLiteral("_Compilado.gpkg"));
    const QString projectPath = inputDir.filePath(QStringLiteral("_Proyecto.qgz"));

    // Remove a previous GeoPackage so we start clean
    if (QFile::exists(gpkgPath)) {
        QFile::remove(gpkgPath);
    }

    // ------------------------------------------------------------------
    // 4. Write every shapefile as a layer inside the GeoPackage
    // ------------------------------------------------------------------
    QgsCoordinateTransformContext transformCtx;

    for (const QString &shpFile : shpFiles) {
        const QString shpPath = inputDir.filePath(shpFile);
        const QString layerName = QFileInfo(shpFile).baseName();

        // Load source layer
        QgsVectorLayer srcLayer(shpPath, layerName, QStringLiteral("ogr"));
        if (!srcLayer.isValid()) {
            emit processingFinished(false,
                tr("No se pudo cargar el shapefile: %1").arg(shpPath));
            return;
        }

        // Prepare writer options
        QgsVectorFileWriter::SaveVectorOptions options;
        options.driverName   = QStringLiteral("GPKG");
        options.layerName    = layerName;
        // First layer creates the file; subsequent ones append
        options.actionOnExistingFile = QFile::exists(gpkgPath)
            ? QgsVectorFileWriter::CreateOrOverwriteLayer
            : QgsVectorFileWriter::CreateOrOverwriteFile;

        QString errorMsg;
        QString newFilename;
        QString newLayerName;

        const QgsVectorFileWriter::WriterError result =
            QgsVectorFileWriter::writeAsVectorFormatV3(
                &srcLayer,
                gpkgPath,
                transformCtx,
                options,
                &errorMsg,
                &newFilename,
                &newLayerName
            );

        if (result != QgsVectorFileWriter::NoError) {
            emit processingFinished(false,
                tr("Error al escribir la capa '%1' en el GeoPackage: %2")
                    .arg(layerName, errorMsg));
            return;
        }
    }

    // ------------------------------------------------------------------
    // 5. Create a QGIS project and load all layers from the GeoPackage
    // ------------------------------------------------------------------
    QgsProject project;
    int stylesFailed = 0;

    for (const QString &shpFile : shpFiles) {
        const QString layerName = QFileInfo(shpFile).baseName();

        // OGR connection string for a GPKG layer
        const QString uri = QStringLiteral("%1|layername=%2")
                                .arg(gpkgPath, layerName);

        auto *layer = new QgsVectorLayer(uri, layerName, QStringLiteral("ogr"));
        if (!layer->isValid()) {
            delete layer;
            emit processingFinished(false,
                tr("No se pudo cargar la capa '%1' desde el GeoPackage.")
                    .arg(layerName));
            return;
        }

        // ------------------------------------------------------------------
        // 6. Apply QML style if a matching file exists
        // ------------------------------------------------------------------
        if (!styleDir.isEmpty()) {
            QDir styleDirObj(styleDir);
            const QString qmlFile = styleDirObj.filePath(layerName + QStringLiteral(".qml"));
            if (QFile::exists(qmlFile)) {
                bool styleOk = false;
                layer->loadNamedStyle(qmlFile, styleOk);
                if (!styleOk) {
                    ++stylesFailed;
                    qWarning("GisProcessor: no se pudo aplicar el estilo '%s' a la capa '%s'",
                             qPrintable(qmlFile), qPrintable(layerName));
                }
            }
        }

        project.addMapLayer(layer, /*addToLegend=*/true);
    }

    // ------------------------------------------------------------------
    // 7. Save the QGIS project as .qgz
    // ------------------------------------------------------------------
    project.setFileName(projectPath);
    if (!project.write()) {
        emit processingFinished(false,
            tr("No se pudo guardar el proyecto QGIS en: %1").arg(projectPath));
        return;
    }

    QString successMsg = tr("¡Proceso completado!\nGeoPackage: %1\nProyecto QGIS: %2")
                             .arg(gpkgPath, projectPath);
    if (stylesFailed > 0) {
        successMsg += tr("\n\nAdvertencia: %n estilo(s) no pudo(eron) aplicarse. "
                         "Revisa el log para más detalles.", "", stylesFailed);
    }
    emit processingFinished(true, successMsg);
}
