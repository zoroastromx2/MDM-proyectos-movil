cmake_minimum_required(VERSION 3.19)
project(MDMProyectosMovil VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# --- Qt ---
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui Widgets Xml Qml Quick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Widgets Xml Qml Quick)

if(Qt${QT_VERSION_MAJOR}Quick_VERSION VERSION_GREATER_EQUAL "6.0")
    find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
endif()

# --- QGIS ---
# Locate QGIS installation. Users may override QGIS_PREFIX_PATH via -DQGIS_PREFIX_PATH=...
if(NOT DEFINED QGIS_PREFIX_PATH)
    set(QGIS_PREFIX_PATH "" CACHE PATH "Path to the QGIS installation prefix (e.g. /usr or /usr/local)")
endif()

# Try to find qgis_core via its CMake config (available in recent QGIS builds)
find_package(QGIS QUIET CONFIG HINTS "${QGIS_PREFIX_PATH}/lib/cmake/QGIS")

if(QGIS_FOUND)
    # Modern QGIS CMake config provides imported targets
    if(TARGET QGIS::Core)
        set(QGIS_TARGETS QGIS::Core)
    endif()
    if(TARGET QGIS::Gui)
        list(APPEND QGIS_TARGETS QGIS::Gui)
    endif()
    message(STATUS "Found QGIS via CMake config: ${QGIS_VERSION}")
else()
    # Fall back to manual search
    find_library(QGIS_CORE_LIBRARY
        NAMES qgis_core
        HINTS
            "${QGIS_PREFIX_PATH}/lib"
            /lib
            /local/lib
            /lib/x86_64-linux-gnu
            /lib64
    )

    find_library(QGIS_GUI_LIBRARY
        NAMES qgis_gui
        HINTS
            "${QGIS_PREFIX_PATH}/lib"
            /lib
            /local/lib
            /lib/x86_64-linux-gnu
            /lib64
    )

    find_path(QGIS_INCLUDE_DIR
        NAMES qgsapplication.h
        HINTS
            "${QGIS_PREFIX_PATH}/include"
            /include/qgis
            /local/include/qgis
    )

    if(NOT QGIS_CORE_LIBRARY OR NOT QGIS_INCLUDE_DIR)
        message(FATAL_ERROR
            "Could not find qgis_core. "
            "Please set QGIS_PREFIX_PATH to your QGIS installation prefix, e.g.:\n"
            "  cmake -DQGIS_PREFIX_PATH=/usr .."
        )
    endif()

    add_library(QGIS_Core UNKNOWN IMPORTED)
    set_target_properties(QGIS_Core PROPERTIES
        IMPORTED_LOCATION "${QGIS_CORE_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${QGIS_INCLUDE_DIR}"
    )

    set(QGIS_TARGETS QGIS_Core)

    if(QGIS_GUI_LIBRARY)
        add_library(QGIS_Gui UNKNOWN IMPORTED)
        set_target_properties(QGIS_Gui PROPERTIES
            IMPORTED_LOCATION "${QGIS_GUI_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${QGIS_INCLUDE_DIR}"
        )
        list(APPEND QGIS_TARGETS QGIS_Gui)
        message(STATUS "Found qgis_gui: ${QGIS_GUI_LIBRARY}")
    endif()

    message(STATUS "Found qgis_core: ${QGIS_CORE_LIBRARY}")
    message(STATUS "QGIS include dir: ${QGIS_INCLUDE_DIR}")
endif()

# --- GDAL / OGR ---
find_package(GDAL QUIET)

if(GDAL_FOUND)
    message(STATUS "Found GDAL: ${GDAL_VERSION}")
else()
    # Fallback for OSGeo4W / manual installations
    get_filename_component(OSGEO4W_ROOT "${GDAL_PREFIX_PATH}" DIRECTORY)

    find_path(GDAL_INCLUDE_DIR
        NAMES ogr_api.h
        HINTS
            "${GDAL_PREFIX_PATH}/include"
            "${OSGEO4W_ROOT}/include"
            "${OSGEO4W_ROOT}/apps/gdal/include"
            /include
            /local/include
    )

    find_library(GDAL_LIBRARY
        NAMES gdal gdal_i
        HINTS
            "${GDAL_PREFIX_PATH}/lib"
            "${OSGEO4W_ROOT}/lib"
            "${OSGEO4W_ROOT}/apps/gdal/lib"
            /lib
            /local/lib
            /lib/x86_64-linux-gnu
            /lib64
    )

    if(NOT GDAL_INCLUDE_DIR OR NOT GDAL_LIBRARY)
        message(FATAL_ERROR
            "Could not find GDAL/OGR. "
            "Please install GDAL and/or set GDAL_PREFIX_PATH to your GDAL installation prefix."
        )
    endif()

    add_library(GDAL::GDAL UNKNOWN IMPORTED)
    set_target_properties(GDAL::GDAL PROPERTIES
        IMPORTED_LOCATION "${GDAL_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${GDAL_INCLUDE_DIR}"
    )

    message(STATUS "Found GDAL include dir: ${GDAL_INCLUDE_DIR}")
    message(STATUS "Found GDAL library: ${GDAL_LIBRARY}")
endif()

# --- Sources ---
set(PROJECT_SOURCES
    main.cpp
    GisProcessor.h
    GisProcessor.cpp
)

qt_add_executable(MDMProyectosMovil
    ${PROJECT_SOURCES}
)

qt_add_qml_module(MDMProyectosMovil
    URI MDMProyectosMovil
    VERSION 1.0
    QML_FILES main.qml
)

target_link_libraries(MDMProyectosMovil
    PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Gui
        Qt${QT_VERSION_MAJOR}::Widgets
        Qt${QT_VERSION_MAJOR}::Xml
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Quick
        ${QGIS_TARGETS}
        GDAL::GDAL
)

if(Qt${QT_VERSION_MAJOR}Quick_VERSION VERSION_GREATER_EQUAL "6.0")
    target_link_libraries(MDMProyectosMovil PRIVATE Qt6::QuickControls2)
endif()

# Ensure include dirs are visible (redundant when using imported targets, but harmless)
if(QGIS_INCLUDE_DIR)
    target_include_directories(MDMProyectosMovil PRIVATE "${QGIS_INCLUDE_DIR}")
endif()

if(GDAL_INCLUDE_DIR)
    target_include_directories(MDMProyectosMovil PRIVATE "${GDAL_INCLUDE_DIR}")
endif()

install(TARGETS MDMProyectosMovil
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
