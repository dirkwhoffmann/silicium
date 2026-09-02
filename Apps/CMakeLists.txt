# Silicium consists of three applications:
#
# Silicium – Main application
#
#   This is the application users launch first. It organizes virtual machines in
#   a library and provides settings that can be shared across emulator instances.
#   Virtual machines are started through the hub, which launches the appropriate
#   emulator backend as a separate process.
#
# SiC64 – Commodore 64 backend
#
#   This application is the Commodore 64 emulator. It is based on the VirtualC64
#   core, which was originally developed over many years as a standalone macOS
#   application.
#
# SiAmiga – Commodore Amiga backend
#
#   This application is the Commodore Amiga emulator. It is based on the vAmiga
#   core, which was originally developed over many years as a standalone macOS
#   application.
#
#   The Amiga backend has not yet been integrated into Silicium. It is planned
#   for a future major release after alpha testing of the C64 backend has been
#   completed successfully.

#
# Version
#
# The single place the application's version is stated. It reaches the code
# through the generated version.h (included by config.h) and the bundles
# through the Info.plist properties below, so the number in the About box and
# the one macOS reports come from the same source and cannot drift.
#
# This is the app version. The emulator cores version themselves separately
# (see Cores/VCCore/vcconfig.h).

set(SI_VERSION_MAJOR    0)
set(SI_VERSION_MINOR    1)
set(SI_VERSION_SUBMINOR 0)
set(SI_VERSION_BETA     1)

# @ONLY: the template contains no ${...} of its own, and restricting
# substitution to @VAR@ keeps it that way if C++ preprocessor text is ever
# added to it.
configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/version.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/version.h"
        @ONLY)

#
# Bundle metadata
#
# CFBundleShortVersionString has to be one to three dot-separated integers, so
# the beta suffix that AppController::version() appends ("0.1b1") cannot go in
# it -- the numeric part goes there, and the beta rides along in
# CFBundleVersion, which is free-form.

set(SI_VERSION "${SI_VERSION_MAJOR}.${SI_VERSION_MINOR}.${SI_VERSION_SUBMINOR}")
set(SI_BUILD_VERSION "${SI_VERSION}")
if(SI_VERSION_BETA GREATER 0)
    set(SI_BUILD_VERSION "${SI_VERSION}b${SI_VERSION_BETA}")
endif()

message(STATUS "Silicium version: ${SI_BUILD_VERSION}")

# Reverse-DNS identifier taken from the author's domain, which appears in every
# source header. Without this CMake falls back to "com.yourcompany.<target>",
# a placeholder that macOS would happily treat as the app's permanent identity
# -- it keys Gatekeeper, TCC permissions and Launch Services.
set(SI_BUNDLE_PREFIX "de.dirkwhoffmann")

set(SI_COPYRIGHT "Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de")

set(ICON_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets/icons/AppIcon.icns")
set(ICON_FILE_C64 "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets/icons/AppIconC64.icns")

set_source_files_properties(${ICON_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
set_source_files_properties(${ICON_FILE_C64} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/Shared/Theme/Fonts.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/Shared/Theme/Sounds.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/Shared/Theme/Style.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/Shared/Theme/Size.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

#
# Silicium
#

qt_add_executable(silicium
        MACOSX_BUNDLE
        "Silicium/main.cpp"
        ${ICON_FILE})

set_target_properties(silicium PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Apps/bin"
        MACOSX_BUNDLE_ICON_FILE AppIcon.icns
        MACOSX_BUNDLE_BUNDLE_NAME "Silicium"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${SI_BUNDLE_PREFIX}.silicium"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${SI_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${SI_BUILD_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "${SI_COPYRIGHT}")

# The binary dir carries the generated version.h, which config.h includes.
target_include_directories(silicium PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(silicium PRIVATE
        utlib
        rvlib
        Qt6::Core
        Qt6::Concurrent
        Qt6::Gui
        Qt6::Multimedia
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickDialogs2
        Qt6::QuickEffects
        SDL3::SDL3)

# Compiler options
target_compile_options(silicium PRIVATE

        # MSVC
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
        # $<$<CXX_COMPILER_ID:MSVC>:/WX>
        $<$<CXX_COMPILER_ID:MSVC>:/Zc:preprocessor>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4100>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4172>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4201>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4324>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4458>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4702>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4805>
        $<$<CXX_COMPILER_ID:MSVC>:/wd4996>

        # GCC
        $<$<CXX_COMPILER_ID:GNU>:-Wall>
        $<$<CXX_COMPILER_ID:GNU>:-Werror>
        $<$<CXX_COMPILER_ID:GNU>:-Wno-restrict>
        $<$<CXX_COMPILER_ID:GNU>:-Wno-unused-parameter>
        $<$<CXX_COMPILER_ID:GNU>:-Wno-attributes>
        $<$<CXX_COMPILER_ID:GNU>:-fconcepts>

        # Clang / AppleClang
        $<$<CXX_COMPILER_ID:Clang>:-Wall>
        $<$<CXX_COMPILER_ID:Clang>:-Werror>
        $<$<CXX_COMPILER_ID:Clang>:-Wno-unused-parameter>
        $<$<CXX_COMPILER_ID:Clang>:-Wno-gnu-anonymous-struct>
        $<$<CXX_COMPILER_ID:Clang>:-Wno-nested-anon-types>
        $<$<CXX_COMPILER_ID:AppleClang>:-Wall>
        $<$<CXX_COMPILER_ID:AppleClang>:-Werror>
        $<$<CXX_COMPILER_ID:AppleClang>:-Wno-unused-parameter>
        $<$<CXX_COMPILER_ID:AppleClang>:-Wno-gnu-anonymous-struct>
        $<$<CXX_COMPILER_ID:AppleClang>:-Wno-nested-anon-types>
)

# Assets under Shared/Assets are embedded into both apps (icons, images,
# fonts, sounds, markdown, ...). BASE = Shared/Assets, so a file such as
# Shared/Assets/images/foo.png becomes :/images/foo.png. The glob is recursive
# and indiscriminate, so drop everything that isn't content: the Assets.cpp/.h
# in that folder are C++ sources compiled elsewhere, the CMakeLists.txt builds
# them, and .DS_Store is Finder litter.
file(GLOB_RECURSE ASSET_RESOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets/*")
list(FILTER ASSET_RESOURCES EXCLUDE REGEX "\\.(cpp|h)$")
list(FILTER ASSET_RESOURCES EXCLUDE REGEX "/(CMakeLists\\.txt|\\.DS_Store)$")

qt_add_resources(silicium "assets_files"
        PREFIX "/"
        BASE "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets"
        FILES ${ASSET_RESOURCES})

# The showcase virtual machines are Silicium (Hub) content only -- SiC64 has no
# use for them -- so they live under Silicium/ rather than Shared/Assets. BASE =
# Silicium keeps their resource prefix at :/Showcases/..., which is what
# HubController::setupShowcases() reads.
# Finder litter would otherwise be embedded in the binary and extracted into
# the showcase folder at runtime (see the same filter above).
file(GLOB_RECURSE SHOWCASE_RESOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Silicium/Showcases/*")
list(FILTER SHOWCASE_RESOURCES EXCLUDE REGEX "/\\.DS_Store$")

qt_add_resources(silicium "showcase_files"
        PREFIX "/"
        BASE "${CMAKE_CURRENT_SOURCE_DIR}/Silicium"
        FILES ${SHOWCASE_RESOURCES})

file(GLOB_RECURSE SILICIUM_QML_SOURCES CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/Silicium/*.qml"
        "${CMAKE_CURRENT_SOURCE_DIR}/Shared/*.qml")
list(TRANSFORM SILICIUM_QML_SOURCES REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "")

qt_add_qml_module(silicium
        URI siliciumUI
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/silicium/siliciumUI"
        QML_FILES ${SILICIUM_QML_SOURCES})

#
# SiC64
#

qt_add_executable(SiC64
        MACOSX_BUNDLE
        "SiC64/main.cpp"
        ${ICON_FILE_C64})

# The target name matches this source subdirectory's name, which would
# otherwise collide with the build-tree mirror CMake creates for it. Give
# the binary its own output directory to avoid that clash.
set_target_properties(SiC64 PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Apps/bin"
        MACOSX_BUNDLE_ICON_FILE AppIconC64.icns
        MACOSX_BUNDLE_BUNDLE_NAME "SiC64"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${SI_BUNDLE_PREFIX}.SiC64"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${SI_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${SI_BUILD_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "${SI_COPYRIGHT}")

# The binary dir carries the generated version.h, which config.h includes.
target_include_directories(SiC64 PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(SiC64 PRIVATE
        utlib
        rvlib
        VCCore
        Qt6::Core
        Qt6::Gui
        Qt6::Multimedia
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickDialogs2
        Qt6::QuickEffects
        SDL3::SDL3)

# SiC64 embeds the same Shared/Assets tree as silicium (but not the showcases,
# which now live under Silicium/ and are therefore excluded automatically).
qt_add_resources(SiC64 "assets_files"
        PREFIX "/"
        BASE "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets"
        FILES ${ASSET_RESOURCES})

file(GLOB_RECURSE SIC64_QML_SOURCES CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/SiC64/*.qml"
        "${CMAKE_CURRENT_SOURCE_DIR}/Shared/*.qml")
list(TRANSFORM SIC64_QML_SOURCES REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "")

# SiC64's module must use a different URI from silicium's. Two QML modules that
# declare the same URI in the same CMake configuration clash during type
# registration -- the app nondeterministically fails to resolve some of its own
# types ("X is not a type"). The two apps were kept apart by living in separate
# directory scopes before; now that both modules are defined here, they need
# distinct URIs. This changes SiC64's resource prefix to qrc:/qt/qml/sic64UI/...
# (see SiC64/main.cpp). Shared QML types still resolve for both apps via the
# implicit same-module import, so no shared .qml needs an explicit module import.
qt_add_qml_module(SiC64
        URI sic64UI
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/SiC64/sic64UI"
        QML_FILES ${SIC64_QML_SOURCES})

#
# SiAmiga
#
# Stub only: proves VACore links and runs inside a standalone app, and that
# the build chain accommodates a third executable alongside silicium and
# SiC64. The real Amiga backend (an equivalent of C64Controller and friends)
# is built out in a later step, once the Amiga UI work begins in earnest.
# There is no dedicated Amiga app icon yet, so this reuses silicium's
# ICON_FILE rather than fabricating a placeholder asset.
#

qt_add_executable(SiAmiga
        MACOSX_BUNDLE
        "SiAmiga/main.cpp"
        ${ICON_FILE})

# The target name matches this source subdirectory's name, which would
# otherwise collide with the build-tree mirror CMake creates for it. Give
# the binary its own output directory to avoid that clash.
set_target_properties(SiAmiga PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Apps/bin"
        MACOSX_BUNDLE_ICON_FILE AppIcon.icns
        MACOSX_BUNDLE_BUNDLE_NAME "SiAmiga"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${SI_BUNDLE_PREFIX}.SiAmiga"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${SI_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${SI_BUILD_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "${SI_COPYRIGHT}")

# The binary dir carries the generated version.h, which config.h includes.
target_include_directories(SiAmiga PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(SiAmiga PRIVATE
        utlib
        rvlib
        VACore
        Qt6::Core
        Qt6::Gui
        Qt6::Multimedia
        Qt6::Quick
        Qt6::QuickControls2
        SDL3::SDL3)

# SiAmiga embeds the same Shared/Assets tree as the other two apps.
qt_add_resources(SiAmiga "assets_files"
        PREFIX "/"
        BASE "${CMAKE_CURRENT_SOURCE_DIR}/Shared/Assets"
        FILES ${ASSET_RESOURCES})

file(GLOB_RECURSE SIAMIGA_QML_SOURCES CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/SiAmiga/*.qml"
        "${CMAKE_CURRENT_SOURCE_DIR}/Shared/*.qml")
list(TRANSFORM SIAMIGA_QML_SOURCES REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "")

# The config window pulls in the shared chrome components (SettingsPage,
# ConfigToolbar, ...), so Shared/*.qml joins the module now -- see main.cpp
# for the Assets/Preferences/Theme singletons those components need.
#
# SiAmiga's module needs its own URI, for the same reason SiC64's does (see
# the comment above qt_add_qml_module(SiC64, ...)).
qt_add_qml_module(SiAmiga
        URI siamigaUI
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/SiAmiga/siamigaUI"
        QML_FILES ${SIAMIGA_QML_SOURCES})

#
# Subdirectories
#

add_subdirectory(Silicium)
add_subdirectory(SiC64)
add_subdirectory(SiAmiga)
add_subdirectory(Shared)

target_sources(silicium PRIVATE debug.cpp)
