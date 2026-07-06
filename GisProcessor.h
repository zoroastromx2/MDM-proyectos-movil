#pragma once

#include <QObject>
#include <QString>

/**
 * @class GisProcessor
 * @brief Backend C++ que automatiza la creación de un GeoPackage y un proyecto
 *        QGIS (.qgz) a partir de un directorio de shapefiles y otro de estilos.
 *
 * Esta clase se registra en el contexto de QML y expone el método
 * processDirectory() como Q_INVOKABLE para que pueda ser invocado directamente
 * desde la interfaz.
 */
class GisProcessor : public QObject
{
    Q_OBJECT

public:
    explicit GisProcessor(QObject *parent = nullptr);

    /**
     * @brief Procesa un directorio de shapefiles y genera un GeoPackage y un
     *        proyecto QGIS (.qgz).
     *
     * @param shapeDirUrl  URL de directorio (puede ser file:///...) que contiene
     *                     los archivos .shp.
     * @param styleDirUrl  URL de directorio que contiene los archivos .qml de
     *                     estilos (puede estar vacío).
     */
    Q_INVOKABLE void processDirectory(const QString &shapeDirUrl,
                                      const QString &styleDirUrl);

signals:
    /** Emitida justo antes de iniciar el procesamiento. */
    void processingStarted();

    /**
     * Emitida cuando el procesamiento finaliza.
     * @param success  true si todo fue correcto, false si hubo algún error.
     * @param message  Mensaje informativo o de error para mostrar al usuario.
     */
    void processingFinished(bool success, QString message);
};
