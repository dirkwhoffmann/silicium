target_include_directories(silicium PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Animations
        ${CMAKE_CURRENT_SOURCE_DIR}/Components
        ${CMAKE_CURRENT_SOURCE_DIR}/Compounds)

target_include_directories(SiC64 PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Animations
        ${CMAKE_CURRENT_SOURCE_DIR}/Components
        ${CMAKE_CURRENT_SOURCE_DIR}/Compounds)

target_include_directories(SiAmiga PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Animations
        ${CMAKE_CURRENT_SOURCE_DIR}/Components
        ${CMAKE_CURRENT_SOURCE_DIR}/Compounds)

file(GLOB_RECURSE CPP_FILES CONFIGURE_DEPENDS  "*.cpp")
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
