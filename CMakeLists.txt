cmake_minimum_required(VERSION 3.19)
project(MDMProyectosMovil VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Prefer package config files (ideal when using vcpkg toolchain)
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

# --- Qt ---
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui Widgets Xml Qml Quick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Widgets Xml Qml Quick)

if(QT_VERSION_MAJOR EQUAL 6)
    # Needed for qt_add_qml_module default resource prefix behavior
    qt_policy(SET QTP0001 NEW)
    find_package(Qt6 REQUIRED COMPONENTS QuickControls2 Dialogs)
endif()

# --- QGIS ---
# User can pass: -DQGIS_PREFIX_PATH=E:/OSGeo4W/apps/qgis
if(NOT DEFINED QGIS_PREFIX_PATH)
    set(QGIS_PREFIX_PATH "E:/OSGeo4W/apps/qgis" CACHE PATH "QGIS installation prefix")
endif()

# Try modern QGIS config package first
# Common locations:
#   E:/OSGeo4W/apps/qgis/lib/cmake/QGIS
#   E:/OSGeo4W/apps/qgis-dev/lib/cmake/QGIS
find_package(QGIS QUIET CONFIG
    HINTS
        "${QGIS_PREFIX_PATH}/lib/cmake/QGIS"
        "${QGIS_PREFIX_PATH}/cmake"
)

if(QGIS_FOUND)
    set(QGIS_TARGETS "")
    if(TARGET QGIS::Core)
        list(APPEND QGIS_TARGETS QGIS::Core)
    endif()
    if(TARGET QGIS::Gui)
        list(APPEND QGIS_TARGETS QGIS::Gui)
    endif()

    if(QGIS_TARGETS STREQUAL "")
        message(FATAL_ERROR "QGIS found but imported targets QGIS::Core / QGIS::Gui were not provided.")
    endif()

    message(STATUS "Found QGIS via CMake config: ${QGIS_VERSION}")
else()
    # Fallback: manual lookup for OSGeo4W-style layout
    find_library(QGIS_CORE_LIBRARY
        NAMES qgis_core
        HINTS
            "${QGIS_PREFIX_PATH}/bin"
            "${QGIS_PREFIX_PATH}/lib"
            "E:/OSGeo4W/apps/qgis/bin"
            "E:/OSGeo4W/apps/qgis/lib"
    )

    find_library(QGIS_GUI_LIBRARY
        NAMES qgis_gui
        HINTS
            "${QGIS_PREFIX_PATH}/bin"
            "${QGIS_PREFIX_PATH}/lib"
            "E:/OSGeo4W/apps/qgis/bin"
            "E:/OSGeo4W/apps/qgis/lib"
    )

    find_path(QGIS_INCLUDE_DIR
        NAMES qgsapplication.h
        HINTS
            "${QGIS_PREFIX_PATH}/include"
            "${QGIS_PREFIX_PATH}/include/qgis"
            "E:/OSGeo4W/apps/qgis/include"
            "E:/OSGeo4W/apps/qgis/include/qgis"
    )

    if(NOT QGIS_CORE_LIBRARY OR NOT QGIS_INCLUDE_DIR)
        message(FATAL_ERROR
            "Could not find QGIS core/include.\n"
            "Set QGIS_PREFIX_PATH, e.g.:\n"
            "  cmake -DQGIS_PREFIX_PATH=E:/OSGeo4W/apps/qgis .."
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
    endif()

    message(STATUS "Found qgis_core: ${QGIS_CORE_LIBRARY}")
    message(STATUS "Found qgis_gui : ${QGIS_GUI_LIBRARY}")
    message(STATUS "QGIS include   : ${QGIS_INCLUDE_DIR}")
endif()

# --- GDAL / OGR ---
# Try package first (vcpkg or system package)
find_package(GDAL QUIET)

if(NOT GDAL_FOUND)
    # Fallback to OSGeo4W-like layout derived from QGIS_PREFIX_PATH
    # Example: QGIS_PREFIX_PATH=E:/OSGeo4W/apps/qgis -> OSGEO4W_ROOT=E:/OSGeo4W
    get_filename_component(_qgis_apps_dir "${QGIS_PREFIX_PATH}" DIRECTORY) # .../apps
    get_filename_component(OSGEO4W_ROOT "${_qgis_apps_dir}" DIRECTORY)      # .../

    find_path(GDAL_INCLUDE_DIR
        NAMES ogr_api.h
        HINTS
            "${OSGEO4W_ROOT}/include"
            "${OSGEO4W_ROOT}/apps/gdal/include"
            "${QGIS_PREFIX_PATH}/include"
    )

    find_library(GDAL_LIBRARY
        NAMES gdal gdal_i gdal312 gdal313 gdal311 gdal310 gdal309
        HINTS
            "${OSGEO4W_ROOT}/bin"
            "${OSGEO4W_ROOT}/lib"
            "${OSGEO4W_ROOT}/apps/gdal/bin"
            "${OSGEO4W_ROOT}/apps/gdal/lib"
            "${QGIS_PREFIX_PATH}/bin"
            "${QGIS_PREFIX_PATH}/lib"
    )

    if(NOT GDAL_INCLUDE_DIR OR NOT GDAL_LIBRARY)
        message(FATAL_ERROR
            "Could not find GDAL/OGR.\n"
            "Install GDAL in OSGeo4W or provide proper paths."
        )
    endif()

    # Create imported target only if GDAL::GDAL does not exist yet
    if(NOT TARGET GDAL::GDAL)
        add_library(GDAL::GDAL UNKNOWN IMPORTED)
        set_target_properties(GDAL::GDAL PROPERTIES
            IMPORTED_LOCATION "${GDAL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${GDAL_INCLUDE_DIR}"
        )
    endif()

    message(STATUS "Found GDAL include: ${GDAL_INCLUDE_DIR}")
    message(STATUS "Found GDAL library: ${GDAL_LIBRARY}")
else()
    message(STATUS "Found GDAL via package config/find module.")
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

if(QT_VERSION_MAJOR EQUAL 6)
    target_link_libraries(MDMProyectosMovil PRIVATE Qt6::QuickControls2 Qt6::Dialogs)
endif()

# Extra include visibility (harmless if already propagated by imported targets)
if(DEFINED QGIS_INCLUDE_DIR AND QGIS_INCLUDE_DIR)
    target_include_directories(MDMProyectosMovil PRIVATE "${QGIS_INCLUDE_DIR}")
endif()

if(DEFINED GDAL_INCLUDE_DIR AND GDAL_INCLUDE_DIR)
    target_include_directories(MDMProyectosMovil PRIVATE "${GDAL_INCLUDE_DIR}")
endif()

include(GNUInstallDirs)
install(TARGETS MDMProyectosMovil
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)