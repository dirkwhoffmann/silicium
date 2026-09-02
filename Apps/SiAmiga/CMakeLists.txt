target_include_directories(SiAmiga PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(SiAmiga PRIVATE
        SiAmigaController.cpp
        SiAmigaRenderer.cpp)
