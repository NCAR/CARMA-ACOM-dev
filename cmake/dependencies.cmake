include(FetchContent)

##################################################################################
# LAPACK

# Try to find BLAS first, then LAPACK
# Use shared libraries preference to avoid static library issues
set(BLA_STATIC OFF)
find_package(BLAS REQUIRED)
find_package(LAPACK REQUIRED)

# ##############################################################################
# Memory check

if(CARMA_ENABLE_MEMCHECK)
  find_file(
    MEMCHECK_SUPPRESS_FILE
    DOC "Suppression file for memory checking"
    NAMES openmpi-valgrind.supp
    PATHS /usr/share/openmpi /usr/lib64/openmpi/share
          /usr/lib64/openmpi/share/openmpi /usr/share)
  if(MEMCHECK_SUPPRESS_FILE)
    set(MEMCHECK_SUPPRESS
        "--suppressions=${PROJECT_SOURCE_DIR}/tests/valgrind.supp --suppressions=${MEMCHECK_SUPPRESS_FILE}"
    )
  else()
    set(MEMCHECK_SUPPRESS
        "--suppressions=${PROJECT_SOURCE_DIR}/tests/valgrind.supp")
  endif()
endif()

##################################################################################
# NetCDF
#
# When CARMA is built inside a host project (e.g. MUSICA, or a model embedding
# MUSICA such as CATChem) NetCDF has usually already been located and exposed as
# an imported target. Different finders use different target names, so probe the
# common variants and reuse a host-provided target before searching ourselves.
# Only when nothing is found do we fall back to pkg-config. CARMA's own sources
# link the canonical carma::netcdf_c / carma::netcdf_fortran targets defined
# below, decoupling them from however NetCDF was located.

# Return the first of ARGN that already exists as a target (target names are
# case-sensitive, so we list each convention explicitly).
function(carma_first_existing_target out_var)
  foreach(candidate ${ARGN})
    if(TARGET ${candidate})
      set(${out_var} ${candidate} PARENT_SCOPE)
      return()
    endif()
  endforeach()
  set(${out_var} "" PARENT_SCOPE)
endfunction()

carma_first_existing_target(CARMA_NETCDF_C_TARGET
  netCDF::netcdf
  NetCDF::NetCDF_C
  netcdf
  NETCDF::NETCDF)
carma_first_existing_target(CARMA_NETCDF_FORTRAN_TARGET
  netCDF::netcdff
  NetCDF::NetCDF_Fortran
  netcdff)

if(CARMA_NETCDF_C_TARGET AND CARMA_NETCDF_FORTRAN_TARGET)
  message(STATUS "CARMA: reusing NetCDF targets from parent project: "
                 "${CARMA_NETCDF_C_TARGET}, ${CARMA_NETCDF_FORTRAN_TARGET}")
else()
  message(STATUS "CARMA: no parent NetCDF target found; locating via pkg-config")
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(netcdff IMPORTED_TARGET REQUIRED netcdf-fortran)
  pkg_check_modules(netcdfc IMPORTED_TARGET REQUIRED netcdf)
  set(CARMA_NETCDF_C_TARGET PkgConfig::netcdfc)
  set(CARMA_NETCDF_FORTRAN_TARGET PkgConfig::netcdff)
endif()

# Canonical targets CARMA's sources link against, regardless of origin.
add_library(carma::netcdf_c INTERFACE IMPORTED GLOBAL)
target_link_libraries(carma::netcdf_c INTERFACE ${CARMA_NETCDF_C_TARGET})
add_library(carma::netcdf_fortran INTERFACE IMPORTED GLOBAL)
target_link_libraries(carma::netcdf_fortran INTERFACE ${CARMA_NETCDF_FORTRAN_TARGET})

##################################################################################
# Google Test

if(PROJECT_IS_TOP_LEVEL)
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG be03d00f5f0cc3a997d1a368bee8a1fe93651f48)

  set(INSTALL_GTEST
      OFF
      CACHE BOOL "" FORCE)
  set(BUILD_GMOCK
      OFF
      CACHE BOOL "" FORCE)

  FetchContent_MakeAvailable(googletest)
endif()
