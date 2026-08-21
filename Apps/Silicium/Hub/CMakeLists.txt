target_include_directories(silicium PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB CPP_FILES CONFIGURE_DEPENDS  "*.cpp")
list(TRANSFORM CPP_FILES REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "")

target_sources(silicium PRIVATE
        ${CPP_FILES}
)
