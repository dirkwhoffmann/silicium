target_include_directories(SiC64 PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Chrome
        ${CMAKE_CURRENT_SOURCE_DIR}/Config
        ${CMAKE_CURRENT_SOURCE_DIR}/Dialogs
        ${CMAKE_CURRENT_SOURCE_DIR}/Inspector
        ${CMAKE_CURRENT_SOURCE_DIR}/Keyboard)

target_sources(SiC64 PRIVATE
        C64Controller.cpp
        SiC64Renderer.cpp
        Config/SiC64ConfigController.cpp
        SiC64InfoController.cpp
        SiC64ActivityController.cpp
        Chrome/SiC64StatusbarController.cpp
        Keyboard/SiC64KeyboardController.cpp
        Inspector/SiC64InspectorController.cpp
        Inspector/SiC64EventController.cpp
        Inspector/SiC64EventTableModel.cpp
        Inspector/SiC64CIAController.cpp
        Inspector/SiC64BusController.cpp
        Inspector/SiC64DmaView.cpp
        Inspector/SiC64CPUController.cpp
        Inspector/SiC64InstructionModel.cpp
        Inspector/SiC64TraceModel.cpp
        Inspector/SiC64MemoryController.cpp
        Inspector/SiC64MemDumpModel.cpp
        Inspector/SiC64Heatmap.cpp
        Inspector/SiC64VICController.cpp
        Inspector/SiC64SIDController.cpp
        Inspector/SiC64Waveform.cpp)
