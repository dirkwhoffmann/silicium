target_include_directories(silicium PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(SiC64 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(SiAmiga PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB CPP_FILES CONFIGURE_DEPENDS  "*.cpp")
list(TRANSFORM CPP_FILES REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "")

target_sources(silicium PRIVATE
        ${CPP_FILES}
)
target_sources(SiC64 PRIVATE
        ${CPP_FILES}
)
target_sources(SiAmiga PRIVATE
        ${CPP_FILES}
)

# SleepGuard.cpp talks to IOKit on macOS
if (APPLE)
    target_link_libraries(silicium PRIVATE "-framework IOKit")
    target_link_libraries(SiC64 PRIVATE "-framework IOKit")
    target_link_libraries(SiAmiga PRIVATE "-framework IOKit")
endif()

add_subdirectory(Assets)
add_subdirectory(Audio)
add_subdirectory(Input)
add_subdirectory(Logger)
add_subdirectory(Preferences)
add_subdirectory(QML)
add_subdirectory(Theme)
add_subdirectory(Video)
