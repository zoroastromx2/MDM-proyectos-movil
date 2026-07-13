import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    width: 640
    height: 480
    minimumWidth: 500
    minimumHeight: 380
    title: qsTr("MDM – Generador de Proyectos QGIS")

    // -----------------------------------------------------------------------
    // Internal state
    // -----------------------------------------------------------------------
    property string shapeFolderPath: ""
    property string styleFolderPath: ""
    property bool   processing: false

    // -----------------------------------------------------------------------
    // Helper: convert a file:// URL string to a display-friendly local path.
    // Uses decodeURIComponent to handle percent-encoded characters (e.g. %20)
    // and mirrors the logic of QUrl::toLocalFile() in C++.
    // -----------------------------------------------------------------------
    function toLocalPath(url) {
        // Decode percent-encoded characters (spaces as %20, etc.)
        var s = decodeURIComponent(url.toString())
        if (s.startsWith("file:///")) {
            // Local file path: file:///home/... (Unix) or file:///C:/... (Windows)
            s = s.substring(7)   // -> "/home/..." or "/C:/..."
            // Windows: remove the spurious leading "/" before the drive letter.
            // Verify charAt(1) is actually a letter to avoid stripping paths like "/1:/folder".
            if (s.length >= 3 && s.charAt(0) === '/'
                    && /[A-Za-z]/.test(s.charAt(1)) && s.charAt(2) === ':') {
                s = s.substring(1)   // "/C:/..." -> "C:/..."
            }
            return s
        }
        // Network / authority-based URL: file://hostname/path
        // This branch is reached for paths that have a hostname (rare on desktop).
        if (s.startsWith("file://")) {
            return s.substring(5)   // preserve "//hostname/path" as UNC-style path
        }
        return s
    }

    // -----------------------------------------------------------------------
    // Folder dialogs (QtQuick.Dialogs – nativo Qt 6, sin dependencia de Qt6Multimedia)
    // -----------------------------------------------------------------------
    FolderDialog {
        id: shapeFolderDialog
        title: qsTr("Selecciona la carpeta de Shapefiles")
        onAccepted: {
            root.shapeFolderPath = selectedFolder.toString()
            shapePathLabel.text  = root.toLocalPath(selectedFolder.toString())
        }
    }

    FolderDialog {
        id: styleFolderDialog
        title: qsTr("Selecciona la carpeta de Estilos QML")
        onAccepted: {
            root.styleFolderPath = selectedFolder.toString()
            stylePathLabel.text  = root.toLocalPath(selectedFolder.toString())
        }
    }

    // -----------------------------------------------------------------------
    // Listen to GisProcessor signals
    // -----------------------------------------------------------------------
    Connections {
        target: gisProcessor

        function onProcessingStarted() {
            root.processing = true
            statusText.color = "#FF8C00"
            statusText.text  = qsTr("Procesando… por favor espera.")
        }

        function onProcessingFinished(success, message) {
            root.processing  = false
            statusText.color = success ? "#2E8B57" : "#CC0000"
            statusText.text  = message
        }
    }

    // -----------------------------------------------------------------------
    // UI layout
    // -----------------------------------------------------------------------
    ColumnLayout {
        anchors {
            fill: parent
            margins: 24
        }
        spacing: 16

        // Title
        Label {
            text: qsTr("Generador de GeoPackage y Proyecto QGIS")
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Divider
        Rectangle { height: 1; color: "#CCCCCC"; Layout.fillWidth: true }

        // --- Shapefile folder ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Carpeta de Shapefiles (.shp):")
                font.pixelSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    id: shapePathLabel
                    text: qsTr("No seleccionada")
                    elide: Text.ElideMiddle
                    color: root.shapeFolderPath === "" ? "#888888" : "#222222"
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Examinar…")
                    enabled: !root.processing
                    onClicked: shapeFolderDialog.open()
                }
            }
        }

        // --- Style folder ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Carpeta de Estilos (.qml):")
                font.pixelSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    id: stylePathLabel
                    text: qsTr("No seleccionada")
                    elide: Text.ElideMiddle
                    color: root.styleFolderPath === "" ? "#888888" : "#222222"
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Examinar…")
                    enabled: !root.processing
                    onClicked: styleFolderDialog.open()
                }
            }
        }

        // Divider
        Rectangle { height: 1; color: "#CCCCCC"; Layout.fillWidth: true }

        // --- Generate button ---
        Button {
            id: generateButton
            text: root.processing ? qsTr("Procesando…") : qsTr("Generar Proyecto")
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 200
            font.pixelSize: 14
            // Enabled only when both folders are selected and not processing
            enabled: (root.shapeFolderPath !== ""
                      && root.styleFolderPath !== ""
                      && !root.processing)

            onClicked: {
                gisProcessor.processDirectory(root.shapeFolderPath,
                                              root.styleFolderPath)
            }
        }

        // --- Status area ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#F5F5F5"
            border.color: "#DDDDDD"
            radius: 4

            Text {
                id: statusText
                anchors {
                    fill: parent
                    margins: 12
                }
                text: qsTr("Selecciona ambas carpetas y pulsa «Generar Proyecto».")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: "#555555"
                verticalAlignment: Text.AlignTop
            }
        }
    }
}
