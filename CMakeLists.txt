cmake_minimum_required(VERSION 3.20)
set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")
project(silicium)

set(CMAKE_CXX_STANDARD 20)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(SDL3 REQUIRED CONFIG)

find_package(Qt6 COMPONENTS
        Core
        Concurrent
        Gui
        Multimedia
        Quick
        QuickControls2
        QuickDialogs2
        QuickEffects
        REQUIRED)

qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

add_subdirectory(Apps)
add_subdirectory(Cores)
