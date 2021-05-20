vcpkg_internal_get_cmake_vars(OUTPUT_FILE _VCPKG_CMAKE_VARS_FILE)
include("${_VCPKG_CMAKE_VARS_FILE}")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO videolan/x265
    REF 07295ba7ab551bb9c1580fdaee3200f1b45711b7 #v3.4
    SHA512 21a4ef8733a9011eec8b336106c835fbe04689e3a1b820acb11205e35d2baba8c786d9d8cf5f395e78277f921857e4eb8622cf2ef3597bce952d374f7fe9ec29
    HEAD_REF master
    PATCHES
        disable-install-pdb.patch
)

set(ENABLE_ASSEMBLY OFF)
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_find_acquire_program(NASM)
    get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
    set(ENV{PATH} "$ENV{PATH};${NASM_EXE_PATH}")
    set(ENABLE_ASSEMBLY ON)
endif ()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)

set(HAS_10_BIT OFF)
if("bit10" IN_LIST FEATURES)
    set(HAS_10_BIT ON)
endif()

set(HAS_12_BIT OFF)
if("bit12" IN_LIST FEATURES)
    set(HAS_12_BIT ON)
endif()
set(FEATURE_OPT_DBG "")
set(FEATURE_OPT_REL "")
set(EXTRA_LIB_DBG "")
set(EXTRA_LIB_REL "")
if(VCPKG_TARGET_IS_WINDOWS)
    set(x265_lib_name "x265-static.lib")
    set(x265_lib_name_main "x265-static-main.lib")
elseif(VCPKG_TARGET_IS_LINUX)
    set(x265_lib_name "libx265.a")
    set(x265_lib_name_main "libx265-main.a")
endif()

if(HAS_10_BIT)
    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}/source
        PREFER_NINJA
        OPTIONS
            -DENABLE_ASSEMBLY=${ENABLE_ASSEMBLY}
            -DENABLE_SHARED=NO
            -DENABLE_LIBNUMA=NO
            -DENABLE_CLI=NO
            -DEXPORT_C_API=NO
            -DHIGH_BIT_DEPTH=YES
    )
    vcpkg_build_cmake()

    set(x265_10_lib "x265-10")
    if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/${x265_lib_name})
        file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/${x265_lib_name} 
            DESTINATION ${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-dbg/${x265_10_lib})
        set(FEATURE_OPT_DBG "-DLINKED_10BIT=ON;${FEATURE_OPT_DBG}")
        set(EXTRA_LIB_DBG "${EXTRA_LIB_DBG}\;${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-dbg/${x265_10_lib}/${x265_lib_name}")
    endif()
    if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/${x265_lib_name})
        file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/${x265_lib_name}
            DESTINATION ${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-rel/${x265_10_lib})
        set(FEATURE_OPT_REL "-DLINKED_10BIT=ON;${FEATURE_OPT_REL}")
        set(EXTRA_LIB_REL "${EXTRA_LIB_REL}\;${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-rel/${x265_10_lib}/${x265_lib_name}")
        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
    endif()
    
endif()

if(HAS_12_BIT)
    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}/source
        PREFER_NINJA
        OPTIONS
            -DENABLE_ASSEMBLY=${ENABLE_ASSEMBLY}
            -DENABLE_SHARED=NO
            -DENABLE_LIBNUMA=NO
            -DENABLE_CLI=NO
            -DEXPORT_C_API=NO
            -DHIGH_BIT_DEPTH=YES
            -DMAIN12=YES
    )
    vcpkg_build_cmake()

    set(x265_12_lib "x265-12")
    if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/${x265_lib_name})
        file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/${x265_lib_name}
            DESTINATION ${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-dbg/${x265_12_lib})
            
        if(VCPKG_TARGET_IS_WINDOWS)
            file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/${x265_lib_def}
                DESTINATION ${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-dbg/${x265_12_lib})
        endif()
        set(FEATURE_OPT_DBG "${FEATURE_OPT_DBG};-DLINKED_12BIT=ON")
        set(EXTRA_LIB_DBG "${EXTRA_LIB_DBG}\;${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-dbg/${x265_12_lib}/${x265_lib_name}")
    endif()
    if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/${x265_lib_name})
        file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/${x265_lib_name}
            DESTINATION ${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-rel/${x265_12_lib})
        set(FEATURE_OPT_REL "${FEATURE_OPT_REL};-DLINKED_12BIT=ON")
        set(EXTRA_LIB_REL "${EXTRA_LIB_REL}\;${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-rel/${x265_12_lib}/${x265_lib_name}")
    endif()
    file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
    file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/source
    PREFER_NINJA
    OPTIONS
        -DENABLE_ASSEMBLY=${ENABLE_ASSEMBLY}
        -DENABLE_SHARED=${ENABLE_SHARED}
        -DENABLE_LIBNUMA=NO
    OPTIONS_RELEASE
        ${FEATURE_OPT_REL}
        -DEXTRA_LIB=${EXTRA_LIB_REL}
    OPTIONS_DEBUG
        -DENABLE_CLI=OFF
        ${FEATURE_OPT_DBG}
        -DEXTRA_LIB=${EXTRA_LIB_DBG}
)

vcpkg_build_cmake()

if(NOT ENABLE_SHARED)
    foreach(BUILDTYPE "debug" "release")
        if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL BUILDTYPE)
            if(BUILDTYPE STREQUAL "debug")
                set(SHORT_BUILDTYPE "dbg")
            else()
                set(SHORT_BUILDTYPE "rel")
            endif()
            if (HAS_10_BIT OR HAS_12_BIT)
                if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name})
                    file(RENAME ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name} ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name_main})
                    set(LIB_FILES "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name_main}")
                    if(HAS_10_BIT)
                        list(APPEND LIB_FILES "${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_10_lib}/${x265_lib_name}")
                    endif()
                    if(HAS_12_BIT)
                        list(APPEND LIB_FILES "${CURRENT_BUILDTREES_DIR}/tmp-${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_12_lib}/${x265_lib_name}")
                    endif()
                    if(VCPKG_TARGET_IS_WINDOWS)
                        string(REPLACE ";" ";" LIB_FILES "${LIB_FILES}")
                        execute_process(COMMAND ${VCPKG_DETECTED_CMAKE_AR} /ignore:4006 /ignore:4221 /OUT:${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name} ${LIB_FILES}  RESULT_VARIABLE AR_EXIT_CODE OUTPUT_VARIABLE AR_STDOUT ERROR_VARIABLE AR_STDERR)
                    elseif(VCPKG_TARGET_IS_LINUX)
                        string(REPLACE ";" "\nADDLIB " LIB_FILES "${LIB_FILES}")
                        execute_process(COMMAND "sh" "-c" "${VCPKG_DETECTED_CMAKE_AR} -M <<EOF
CREATE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}/${x265_lib_name}
ADDLIB ${LIB_FILES}
SAVE
END
EOF" RESULT_VARIABLE AR_EXIT_CODE OUTPUT_VARIABLE AR_STDOUT ERROR_VARIABLE AR_STDERR)
                    endif()
                    if(NOT (AR_EXIT_CODE EQUAL 0))
                        message(FATAL_ERROR "ar exit code: ${AR_EXIT_CODE} out: ${AR_STDOUT} err: ${AR_STDRR}")
                    endif()
                endif()
            endif()
        endif()
    endforeach()
endif()

foreach(BUILDTYPE "debug" "release")
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL BUILDTYPE)
        if(BUILDTYPE STREQUAL "debug")
            set(SHORT_BUILDTYPE "dbg")
            set(CONFIG "Debug")
        else()
            set(SHORT_BUILDTYPE "rel")
            set(CONFIG "Release")
        endif()

    message(STATUS "Installing ${TARGET_TRIPLET}-${SHORT_BUILDTYPE}")

        vcpkg_execute_build_process(
            COMMAND ${CMAKE_COMMAND} --install . --config ${CONFIG}
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_BUILDTYPE}
            LOGNAME "${arg_LOGFILE_ROOT}-${TARGET_TRIPLET}-${SHORT_BUILDTYPE}"
        )

    endif()
endforeach()

vcpkg_copy_pdbs()

# remove duplicated include files
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
endif()
vcpkg_copy_tools(TOOL_NAMES x265 AUTO_CLEAN)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static" OR VCPKG_TARGET_IS_LINUX)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND (NOT VCPKG_TARGET_IS_MINGW))
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
            vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x265.pc" "-lx265" "-lx265-static")
        endif()
        if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
            vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x265.pc" "-lx265" "-lx265-static")
        endif()
    endif()
endif()

# maybe create vcpkg_regex_replace_string?

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(READ ${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x265.pc _contents)
    string(REGEX REPLACE "-l(std)?c\\+\\+" "" _contents "${_contents}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x265.pc "${_contents}")
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(READ ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x265.pc _contents)
    string(REGEX REPLACE "-l(std)?c\\+\\+" "" _contents "${_contents}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x265.pc "${_contents}")
endif()

if(VCPKG_TARGET_IS_MINGW AND ENABLE_SHARED)
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/lib/libx265.a)
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        file(REMOVE ${CURRENT_PACKAGES_DIR}/lib/libx265.a)
    endif()
endif()

if(UNIX)
    foreach(FILE "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x265.pc" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x265.pc")
        if(EXISTS "${FILE}")
            file(READ "${FILE}" _contents)
            string(REPLACE " -lstdc++" "" _contents "${_contents}")
            string(REPLACE " -lc++" "" _contents "${_contents}")
            string(REPLACE " -lgcc_s" "" _contents "${_contents}")
            string(REPLACE " -lgcc" "" _contents "${_contents}")
            string(REPLACE " -lrt" "" _contents "${_contents}")
            file(WRITE "${FILE}" "${_contents}")
        endif()
    endforeach()
    vcpkg_fixup_pkgconfig(SYSTEM_LIBRARIES numa)
else()
    vcpkg_fixup_pkgconfig()
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
