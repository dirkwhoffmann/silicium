target_include_directories(SiC64 PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Chrome
        ${CMAKE_CURRENT_SOURCE_DIR}/Config
        ${CMAKE_CURRENT_SOURCE_DIR}/Dialogs
        ${CMAKE_CURRENT_SOURCE_DIR}/Inspector
        ${CMAKE_CURRENT_SOURCE_DIR}/Keyboard)

target_sources(SiC64 PRIVATE
        C64Controller.cpp
        C64MediaController.cpp
        SiC64Renderer.cpp
        SiC64MergeNode.cpp
        Config/SiC64ConfigController.cpp
        SiC64InfoController.cpp
        SiC64ActivityController.cpp
        Keyboard/SiC64KeyboardController.cpp
        Inspector/SiC64InspectorController.cpp
        Inspector/Events/SiC64EventController.cpp
        Inspector/Events/SiC64EventTableModel.cpp
        Inspector/CIA/SiC64CIAController.cpp
        Inspector/XRay/SiC64XRayController.cpp
        Inspector/XRay/SiC64DmaView.cpp
        Inspector/CPU/SiC64CPUController.cpp
        Inspector/CPU/SiC64InstructionModel.cpp
        Inspector/CPU/SiC64TraceModel.cpp
        Inspector/Memory/SiC64MemoryController.cpp
        Inspector/Memory/SiC64MemDumpModel.cpp
        Inspector/Memory/SiC64Heatmap.cpp
        Inspector/VIC/SiC64VICController.cpp
        Inspector/SID/SiC64SIDController.cpp
        Inspector/SID/SiC64Waveform.cpp)
