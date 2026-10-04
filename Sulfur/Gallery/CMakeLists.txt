# Sulfur Gallery
#
# A small application that shows the Sulfur controls, and the only thing it
# depends on is Sulfur (and Qt). It doubles as a test that the toolkit really
# stands on its own: if something in Sulfur needs the Silicium application,
# this does not build or does not run.
#
#     SulfurGallery                       opens the gallery
#     SulfurGallery --dark                starts in dark mode
#     SulfurGallery --screenshot file.png writes a picture of the window and quits

qt_add_executable(SulfurGallery
        MACOSX_BUNDLE
        main.cpp)

set_target_properties(SulfurGallery PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Sulfur/bin"
        MACOSX_BUNDLE_BUNDLE_NAME "Sulfur Gallery"
        MACOSX_BUNDLE_GUI_IDENTIFIER "de.dirkwhoffmann.SulfurGallery")

qt_add_qml_module(SulfurGallery
        URI SulfurGalleryUI
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/SulfurGalleryUI"
        QML_FILES
        Gallery.qml)

# Sulfur and nothing else of ours
target_link_libraries(SulfurGallery PRIVATE
        Sulfur
        Sulfurplugin
        Qt6::Gui
        Qt6::Quick
        Qt6::QuickControls2)
