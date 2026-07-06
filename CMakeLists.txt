cmake_minimum_required(VERSION 3.19)
project(MDMProyectosMovil VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# --- Qt ---
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Qml Quick)

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
    # Modern QGIS CMake config provides imported target QGIS::Core
    set(QGIS_TARGET QGIS::Core)
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
    set(QGIS_TARGET QGIS_Core)
    message(STATUS "Found qgis_core: ${QGIS_CORE_LIBRARY}")
    message(STATUS "QGIS include dir: ${QGIS_INCLUDE_DIR}")
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
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Quick
        ${QGIS_TARGET}
)

if(Qt${QT_VERSION_MAJOR}Quick_VERSION VERSION_GREATER_EQUAL "6.0")
    target_link_libraries(MDMProyectosMovil PRIVATE Qt6::QuickControls2)
endif()

# Ensure QGIS include dirs are visible (redundant when using imported targets, but harmless)
if(QGIS_INCLUDE_DIR)
    target_include_directories(MDMProyectosMovil PRIVATE "${QGIS_INCLUDE_DIR}")
endif()

install(TARGETS MDMProyectosMovil
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
