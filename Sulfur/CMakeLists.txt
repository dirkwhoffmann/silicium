# Sulfur
#
# The user interface toolkit of Silicium: the theme (colors, fonts, spacing,
# sizes, sounds) and the low-level controls built on it (buttons, menus,
# fields, gauges, ...). It is a QML module of its own and knows nothing about
# the applications that use it.
#
# The one rule: Sulfur never depends on application code. What it needs from
# the application is handed over through SulfurSettings, which an application
# fills in at startup (see Apps/Shared/Preferences/SulfurBridge).
#
# An application uses it by linking the module and its plugin,
#
#     target_link_libraries(MyApp PRIVATE Sulfur Sulfurplugin)
#
# and importing it from QML:
#
#     import Sulfur
#
# Layout:
#
#     src/         C++: Palette (colors), Shortcuts (shortcut texts),
#                  SulfurSettings (what the application tells Sulfur)
#     qml/Theme    Style, Fonts, Size, Sounds
#     qml/Controls the controls (buttons, menus, fields, gauges, ...)
#     qml/Compounds labeled controls built from them (SuLabeled and its
#                  variants), knobs and sliders, notifications
#     qml/Dialogs  the dialog frame and the standard dialogs
#     resources/   fonts and sounds the theme needs

# The theme singletons
foreach(name Style Fonts Size Sounds)
    set_source_files_properties("qml/Theme/${name}.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
endforeach()

file(GLOB_RECURSE SULFUR_QML CONFIGURE_DEPENDS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "qml/*.qml")

# Fonts and sounds sit directly under the module's resource path, e.g.
# qrc:/qt/qml/Sulfur/fonts/Phosphor.ttf
file(GLOB SULFUR_FONTS CONFIGURE_DEPENDS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "resources/fonts/*")
file(GLOB SULFUR_SOUNDS CONFIGURE_DEPENDS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "resources/sounds/*")
list(FILTER SULFUR_FONTS EXCLUDE REGEX "\\.DS_Store$")
list(FILTER SULFUR_SOUNDS EXCLUDE REGEX "\\.DS_Store$")

foreach(file ${SULFUR_FONTS})
    get_filename_component(name "${file}" NAME)
    set_source_files_properties("${file}" PROPERTIES QT_RESOURCE_ALIAS "fonts/${name}")
endforeach()
foreach(file ${SULFUR_SOUNDS})
    get_filename_component(name "${file}" NAME)
    set_source_files_properties("${file}" PROPERTIES QT_RESOURCE_ALIAS "sounds/${name}")
endforeach()

qt_add_qml_module(Sulfur
        URI Sulfur
        VERSION 1.0
        STATIC
        QML_FILES ${SULFUR_QML}
        RESOURCES ${SULFUR_FONTS} ${SULFUR_SOUNDS}
        SOURCES
        src/Palette.h
        src/Palette.cpp
        src/Shortcuts.h
        src/Shortcuts.cpp
        src/SuDialogController.h
        src/SuDialogController.cpp
        src/SulfurSettings.h
        src/SulfurSettings.cpp)

target_include_directories(Sulfur PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/src")

target_link_libraries(Sulfur PUBLIC
        Qt6::Core
        Qt6::Concurrent
        Qt6::Gui
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickEffects
        Qt6::Multimedia)

# The gallery: a small application that depends on nothing but Sulfur
add_subdirectory(Gallery)
