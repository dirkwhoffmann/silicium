target_include_directories(silicium PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(silicium PRIVATE
        Silicium.cpp
        VirtualMachine.cpp
        VirtualMachineLibrary.cpp)

add_subdirectory(Hub)
add_subdirectory(Onboarding)
add_subdirectory(Preferences)
