target_include_directories(SiAmiga PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(SiAmiga PRIVATE
        SiAmController.cpp
        SiAmRenderer.cpp
        SiAmActivityController.cpp
        Config/SiAmConfigController.cpp
        Keyboard/AmigaKeyModel.cpp
        Keyboard/SiAmKeyboardController.cpp
        Inspector/SiAmInspectorController.cpp
        Inspector/SiAmCIAController.cpp
        Inspector/SiAmEventController.cpp
        Inspector/SiAmEventTableModel.cpp
        Inspector/SiAmMemoryController.cpp
        Inspector/SiAmMemDumpModel.cpp
        Inspector/SiAmCopperController.cpp
        Inspector/SiAmCopperListModel.cpp
        Inspector/SiAmGuardModel.cpp
        Inspector/SiAmBlitterController.cpp
        SiAmInfoController.cpp)
