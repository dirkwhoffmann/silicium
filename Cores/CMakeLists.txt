add_library(CoresInterface INTERFACE)
target_include_directories(CoresInterface INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(silicium PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(utlib)
add_subdirectory(rvlib)
add_subdirectory(VCCore)
add_subdirectory(VACore)
