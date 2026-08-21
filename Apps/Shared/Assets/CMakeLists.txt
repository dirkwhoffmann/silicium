target_include_directories(silicium PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(SiC64 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(silicium PRIVATE
        Assets.cpp)
target_sources(SiC64 PRIVATE
        Assets.cpp)
