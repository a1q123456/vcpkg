set(LIBOEXOSIP2_VER "5.2.0")

vcpkg_download_distfile(ARCHIVE
    URLS "https://download-mirror.savannah.gnu.org/releases/exosip/libexosip2-${LIBOEXOSIP2_VER}.tar.gz"
    FILENAME "libexosip2-${LIBOEXOSIP2_VER}.tar.gz"
    SHA512 0abfa695d466a10e67eb89ea5228578e42b713c0aab556e53a76919f7b96069338c3edc151f44566834894244a51cbacda1958612ae58dd2040caa654094d9af
)

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND PATCHES fix-path-in-project.patch)
endif()

vcpkg_extract_source_archive_ex(
    ARCHIVE ${ARCHIVE}
    OUT_SOURCE_PATH SOURCE_PATH
    PATCHES ${PATCHES}
)

if(VCPKG_TARGET_IS_WINDOWS)     
    vcpkg_fail_port_install(ON_ARCH "arm" "arm64")
    
    vcpkg_install_msbuild(
        SOURCE_PATH "${SOURCE_PATH}"
        PROJECT_SUBPATH "platform/vsnet/eXosip.vcxproj"
        INCLUDES_SUBPATH include
        USE_VCPKG_INTEGRATION
        REMOVE_ROOT_INCLUDES      
    )
    
elseif(VCPKG_TARGET_IS_LINUX OR VCPKG_TARGET_IS_OSX)
    vcpkg_configure_make(
        SOURCE_PATH ${SOURCE_PATH}
        OPTIONS ${OPTIONS}
    )

    vcpkg_install_make()
    vcpkg_fixup_pkgconfig()
    
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
