function(handle_versioning VAR_NAME)
        # versioning
        file(STRINGS "cmake/third-party/${VAR_NAME}.version" ${VAR_NAME}_REQUIRED_VERSION)
        list(LENGTH ${VAR_NAME}_REQUIRED_VERSION ${VAR_NAME}_REQUIRED_VERSION_LEN)
        if(${VAR_NAME}_REQUIRED_VERSION_LEN LESS 1)
                message(FATAL_ERROR "Invalid project version file format.")
        endif()
        list(GET ${VAR_NAME}_REQUIRED_VERSION 0 ${VAR_NAME}_REQUIRED_VERSION_PREFIX)
    set(${VAR_NAME}_TAG "main" PARENT_SCOPE)
        set(${VAR_NAME}_TAG "main")
    if(${VAR_NAME}_REQUIRED_VERSION_PREFIX STREQUAL "v")
                if(${VAR_NAME}_REQUIRED_VERSION_LEN LESS 4)
                        message(FATAL_ERROR "Invalid project version file format.")
                endif()
                list(GET ${VAR_NAME}_REQUIRED_VERSION 1 ${VAR_NAME}_REQUIRED_VERSION_MAJOR)
                list(GET ${VAR_NAME}_REQUIRED_VERSION 2 ${VAR_NAME}_REQUIRED_VERSION_MINOR)
                list(GET ${VAR_NAME}_REQUIRED_VERSION 3 ${VAR_NAME}_REQUIRED_VERSION_REVISION)
        set(${VAR_NAME}_REQUIRED_VERSION_MAJOR ${${VAR_NAME}_REQUIRED_VERSION_MAJOR} PARENT_SCOPE)
        set(${VAR_NAME}_REQUIRED_VERSION_MINOR ${${VAR_NAME}_REQUIRED_VERSION_MINOR} PARENT_SCOPE)
        set(${VAR_NAME}_REQUIRED_VERSION_REVISION ${${VAR_NAME}_REQUIRED_VERSION_REVISION} PARENT_SCOPE)
        set(${VAR_NAME}_TAG "v${${VAR_NAME}_REQUIRED_VERSION_MAJOR}.${${VAR_NAME}_REQUIRED_VERSION_MINOR}.${${VAR_NAME}_REQUIRED_VERSION_REVISION}" PARENT_SCOPE)
        set(${VAR_NAME}_TAG "v${${VAR_NAME}_REQUIRED_VERSION_MAJOR}.${${VAR_NAME}_REQUIRED_VERSION_MINOR}.${${VAR_NAME}_REQUIRED_VERSION_REVISION}")
                if(${VAR_NAME}_REQUIRED_VERSION_LEN GREATER 4)
                        list(GET ${VAR_NAME}_REQUIRED_VERSION 4 ${VAR_NAME}_REQUIRED_VERSION_BUILD)
            set(${VAR_NAME}_REQUIRED_VERSION_BUILD ${${VAR_NAME}_REQUIRED_VERSION_BUILD} PARENT_SCOPE)
            set(${VAR_NAME}_TAG "${${VAR_NAME}_TAG}-${${VAR_NAME}_REQUIRED_VERSION_BUILD}" PARENT_SCOPE)
            set(${VAR_NAME}_TAG "${${VAR_NAME}_TAG}-${${VAR_NAME}_REQUIRED_VERSION_BUILD}")
                else()
            set(${VAR_NAME}_REQUIRED_VERSION_BUILD "" PARENT_SCOPE)
            set(${VAR_NAME}_REQUIRED_VERSION_BUILD "")
                endif()
        set(${VAR_NAME}_TAG ${${VAR_NAME}_TAG} PARENT_SCOPE)
        set(${VAR_NAME}_TAG ${${VAR_NAME}_TAG})
        elseif(${VAR_NAME}_REQUIRED_VERSION_PREFIX STREQUAL "")
                message(FATAL_ERROR "No version or tag found for component ${VAR_NAME}")
        else()
                list(GET ${VAR_NAME}_REQUIRED_VERSION 0 ${VAR_NAME}_TAG)
        set(${VAR_NAME}_TAG ${${VAR_NAME}_TAG} PARENT_SCOPE)
        endif()
        message(STATUS "Required ${VAR_NAME} Version: ${${VAR_NAME}_TAG}")
endfunction()

set(_${_COMPONENT_NAME}_INCLUDE_DIR "/usr/local/include")
set(_${_COMPONENT_NAME}_LIB_DIR "/usr/local/lib")
set(_USER_DEFINED_PATHS FALSE)

message(STATUS "===== Configuring Third-Pary: ${_COMPONENT_NAME} =====")

handle_versioning(${_COMPONENT_NAME})
if(${_COMPONENT_NAME} STREQUAL "API_BRIDGE")
    handle_versioning(FRONTEND)
endif()

# Checking for provided pre-installed
if(DEFINED ${_COMPONENT_NAME}_INSTALL_DIR)
    get_filename_component(_${_COMPONENT_NAME}_INCLUDE_DIR "${${_COMPONENT_NAME}_INSTALL_DIR}/include" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
    get_filename_component(_${_COMPONENT_NAME}_LIB_DIR "${${_COMPONENT_NAME}_INSTALL_DIR}/lib" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
    set(_USER_DEFINED_PATHS TRUE)
endif()
if(DEFINED ${_COMPONENT_NAME}_INCLUDE_DIR)
    get_filename_component(_${_COMPONENT_NAME}_INCLUDE_DIR "${${_COMPONENT_NAME}_INCLUDE_DIR}" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
    set(_USER_DEFINED_PATHS TRUE)
endif()
if(DEFINED ${_COMPONENT_NAME}_LIB_DIR)
    get_filename_component(_${_COMPONENT_NAME}_LIB_DIR "${${_COMPONENT_NAME}_LIB_DIR}" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
    set(_USER_DEFINED_PATHS TRUE)
endif()

message(STATUS "${_COMPONENT_NAME}_INCLUDE_DIR: ${_${_COMPONENT_NAME}_INCLUDE_DIR}")
if(NOT ${_HEADER_ONLY})
    message(STATUS "${_COMPONENT_NAME}_LIB_DIR: ${_${_COMPONENT_NAME}_LIB_DIR}")
endif()

# TODO: switch to using find_package
# Finding the specified library
if(${_HEADER_ONLY})
    set(${_COMPONENT_NAME}_LIB_FOUND TRUE)
else()
    find_library(${_COMPONENT_NAME}_LIB_FOUND NAMES ${_COMPONENT_LIB_NAME} lib${_COMPONENT_LIB_NAME} lib${_COMPONENT_LIB_NAME}.a HINTS "${_${_COMPONENT_NAME}_LIB_DIR}")
endif()

# Setting up Library properties if found, pulling from remote if not
if(${_COMPONENT_NAME}_LIB_FOUND AND EXISTS "${_${_COMPONENT_NAME}_INCLUDE_DIR}/${_COMPONENT_HEADER}")
    message(STATUS "FOUND PRE-INSTALLED ${_COMPONENT_NAME}")
    if(${_HEADER_ONLY})
        add_library(${_COMPONENT_LIB_NAME} INTERFACE)
    else()
        add_library(${_COMPONENT_LIB_NAME} UNKNOWN IMPORTED)
    endif()
    if(NOT ${_HEADER_ONLY}) 
        set_property(TARGET ${_COMPONENT_LIB_NAME} PROPERTY IMPORTED_LOCATION "${${_COMPONENT_NAME}_LIB_FOUND}")
    endif()
    set_property(TARGET ${_COMPONENT_LIB_NAME} APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${_${_COMPONENT_NAME}_INCLUDE_DIR}")
elseif(_USER_DEFINED_PATHS)
    message(FATAL_ERROR "FAILED TO FIND PRE-INSTALLED ${_COMPONENT_NAME} AT ABOVE USER-DEFINED PATHS")
else()
    message(STATUS "No user-defined paths (-D${_COMPONENT_NAME}_[INSTALL|INCLUDE|LIB]_DIR) were set")
    message(STATUS "${_COMPONENT_NAME} could not be found at the default location")
    message(STATUS "Downloading and Installing it...")
    include(cmake/third-party/${_COMPONENT_NAME}.cmake)
endif()
target_link_libraries(${PROJECT_NAME} PRIVATE "-Wl,--whole-archive" ${_COMPONENT_LIB_NAME} "-Wl,--no-whole-archive")
