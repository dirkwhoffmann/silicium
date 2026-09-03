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
        SiAmInfoController.cpp)
