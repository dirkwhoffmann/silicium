target_include_directories(SiAmiga PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(SiAmiga PRIVATE
        SiAmController.cpp
        SiAmMediaController.cpp
        SiAmRenderer.cpp
        SiAmMergeNode.cpp
        SiAmActivityController.cpp
        Config/SiAmConfigController.cpp
        Keyboard/AmigaKeyModel.cpp
        Keyboard/SiAmKeyboardController.cpp
        Inspector/SiAmInspectorController.cpp
        Inspector/CIA/SiAmCIAController.cpp
        Inspector/Events/SiAmEventController.cpp
        Inspector/Events/SiAmEventTableModel.cpp
        Inspector/Memory/SiAmMemoryController.cpp
        Inspector/Memory/SiAmMemDumpModel.cpp
        Inspector/Copper/SiAmCopperController.cpp
        Inspector/Copper/SiAmCopperListModel.cpp
        Inspector/SiAmGuardModel.cpp
        Inspector/Blitter/SiAmBlitterController.cpp
        Inspector/Agnus/SiAmAgnusController.cpp
        Inspector/Paula/SiAmPaulaController.cpp
        Inspector/LogicAnalyzer/SiAmLogicAnalyzerController.cpp
        Inspector/XRay/SiAmXRayController.cpp
        Inspector/XRay/SiAmDmaView.cpp
        Inspector/LogicAnalyzer/SiAmLogicView.cpp
        Inspector/CPU/SiAmInstructionModel.cpp
        Inspector/CPU/SiAmTraceModel.cpp
        Inspector/CPU/SiAmCPUController.cpp
        Inspector/Denise/SiAmDeniseController.cpp
        Inspector/Denise/SiAmSpriteView.cpp
        Inspector/Port/SiAmPortController.cpp
        SiAmInfoController.cpp)
