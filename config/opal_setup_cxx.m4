dnl -*- shell-script -*-
dnl
dnl Copyright (c) 2004-2005 The Trustees of Indiana University and Indiana
dnl                         University Research and Technology
dnl                         Corporation.  All rights reserved.
dnl Copyright (c) 2004-2006 The University of Tennessee and The University
dnl                         of Tennessee Research Foundation.  All rights
dnl                         reserved.
dnl Copyright (c) 2004-2008 High Performance Computing Center Stuttgart,
dnl                         University of Stuttgart.  All rights reserved.
dnl Copyright (c) 2004-2006 The Regents of the University of California.
dnl                         All rights reserved.
dnl Copyright (c) 2006      Los Alamos National Security, LLC.  All rights
dnl                         reserved.
dnl Copyright (c) 2007-2009 Sun Microsystems, Inc.  All rights reserved.
dnl Copyright (c) 2008-2013 Cisco Systems, Inc.  All rights reserved.
dnl Copyright (c) 2015-2016 Research Organization for Information Science
dnl                         and Technology (RIST). All rights reserved.
dnl Copyright (c) 2020      Triad National Security, LLC. All rights
dnl                         reserved.
dnl Copyright (c) 2021      IBM Corporation.  All rights reserved.
dnl
dnl $COPYRIGHT$
dnl
dnl Additional copyrights may follow
dnl
dnl $HEADER$
dnl

# This macro is necessary to get the title to be displayed first.  :-)
AC_DEFUN([OPAL_SETUP_CXX_BANNER],[
    opal_show_subtitle "C++ compiler and preprocessor"
])

# This macro is necessary because PROG_CXX* is REQUIREd by multiple
# places in SETUP_CXX.
AC_DEFUN([OPAL_PROG_CXX],[
    OPAL_VAR_SCOPE_PUSH([opal_cxxflags_save])
    opal_cxxflags_save="$CXXFLAGS"
    AC_PROG_CXX
    AC_PROG_CXXCPP
    CXXFLAGS="$opal_cxxflags_save"
    OPAL_VAR_SCOPE_POP
])

# OPAL_SETUP_CXX()
# ----------------
# Do everything required to setup the C++ compiler.  Safe to AC_REQUIRE
# this macro.
AC_DEFUN([OPAL_SETUP_CXX],[
    AC_REQUIRE([OPAL_SETUP_CXX_BANNER])

    _OPAL_SETUP_CXX_COMPILER

    OPAL_CXX_COMPILER_VENDOR([opal_cxx_vendor])

    _OPAL_SETUP_CXX_COMPILER_BACKEND
])

# _OPAL_SETUP_CXX_COMPILER()
# --------------------------
# Setup the CXX compiler
AC_DEFUN([_OPAL_SETUP_CXX_COMPILER],[
    OPAL_VAR_SCOPE_PUSH(opal_cxx_compiler_works)

    # Must REQUIRE the PROG_CXX macro and not call it directly here for
    # reasons well-described in the AC2.64 (and beyond) docs.
    AC_REQUIRE([OPAL_PROG_CXX])
    BASECXX="`basename $CXX`"

    AS_IF([test "x$CXX" = "x"], [CXX=none])
    set dummy $CXX
    opal_cxx_argv0=[$]2
    OPAL_WHICH([$opal_cxx_argv0], [OPAL_CXX_ABSOLUTE])
    AS_IF([test "x$OPAL_CXX_ABSOLUTE" = "x"], [OPAL_CXX_ABSOLUTE=none])

    AC_DEFINE_UNQUOTED(OPAL_CXX, "$CXX", [OPAL underlying C++ compiler])
    AC_SUBST(OPAL_CXX_ABSOLUTE)

    OPAL_VAR_SCOPE_POP
])

# OPAL_CHECK_CXX_IQUOTE()
# ----------------------
# Check if the compiler supports the -iquote option. This options
# removes the specified directory from the search path when using
# #include <>. This check works around an issue caused by C++20
# which added a <version> header. This conflicts with the
# VERSION file at the base of our source directory on case-
# insensitive filesystems.
AC_DEFUN([OPAL_CHECK_CXX_IQUOTE],[
    OPAL_VAR_SCOPE_PUSH([opal_check_cxx_iquote_CXXFLAGS_save])
    opal_check_cxx_iquote_CXXFLAGS_save=${CXXFLAGS}
    CXXFLAGS="${CXXFLAGS} -iquote ."
    AC_MSG_CHECKING([for $CXX option to add a directory only to the search path for the quote form of include])
    AC_LANG_PUSH(C++)
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[]],[])],
		      [opal_cxx_iquote="-iquote"],
		      [opal_cxx_iquote="-I"])
    CXXFLAGS=${opal_check_cxx_iquote_CXXFLAGS_save}
    AC_LANG_POP(C++)
    OPAL_VAR_SCOPE_POP
    AC_MSG_RESULT([$opal_cxx_iquote])
])

# _OPAL_SETUP_CXX_COMPILER_BACKEND()
# ----------------------------------
# Back end of _OPAL_SETUP_CXX_COMPILER_BACKEND()
AC_DEFUN([_OPAL_SETUP_CXX_COMPILER_BACKEND],[
    AC_LANG_PUSH(C++)
    OPAL_CHECK_CXX_IQUOTE

    # Do we want code coverage
    if test "$WANT_COVERAGE" = "1"; then
        # For compilers > gcc-4.x, use --coverage for
        # compiling and linking to circumvent trouble with
        # libgcov.
        OPAL_COVERAGE_FLAGS=

        _OPAL_CHECK_SPECIFIC_CXXFLAGS(--coverage, coverage)
        if test "$opal_cv_cxx_coverage" = "1" ; then
            OPAL_COVERAGE_FLAGS="--coverage"
            CLEANFILES="*.gcno ${CLEANFILES}"
            CONFIG_CLEAN_FILES="*.gcda *.gcov ${CONFIG_CLEAN_FILES}"
            AC_MSG_WARN([$OPAL_COVERAGE_FLAGS has been added to CXXFLAGS (--enable-coverage)])
        else
            _OPAL_CHECK_SPECIFIC_CXXFLAGS(-ftest-coverage, ftest_coverage)
            _OPAL_CHECK_SPECIFIC_CXXFLAGS(-fprofile-arcs, fprofile_arcs)
            if test "$opal_cv_cxx_ftest_coverage" = "0" || test "opal_cv_cxx_fprofile_arcs" = "0" ; then
                AC_MSG_WARN([Code coverage functionality is not currently available with $CXX])
                AC_MSG_ERROR([Configure: Cannot continue])
            fi
            CLEANFILES="*.bb *.bbg ${CLEANFILES}"
            OPAL_COVERAGE_FLAGS="-ftest-coverage -fprofile-arcs"
        fi
        OPAL_FLAGS_UNIQ(CXXFLAGS)
        WANT_DEBUG=1
   fi

    # Do we want debugging?
    if test "$WANT_DEBUG" = "1" && test "$enable_debug_symbols" != "no" ; then
        CXXFLAGS="$CXXFLAGS -g"
        AC_MSG_WARN([-g has been added to CXXFLAGS (--enable-debug)])
    fi

    if test "$WANT_DEBUG"  = "0" ; then
        OPAL_ENSURE_CONTAINS_OPTFLAGS(["$CXXFLAGS"])
    fi

    # These flags are generally g++-specific; even the g++-impersonating
    # compilers won't accept them.
    OPAL_CXXFLAGS_BEFORE_PICKY="$CXXFLAGS"
    if test "$WANT_PICKY_COMPILER" = 1; then
        _OPAL_CHECK_SPECIFIC_CXXFLAGS(-Wundef, Wundef)
        _OPAL_CHECK_SPECIFIC_CXXFLAGS(-Wno-long-long, Wno_long_long, int main() { long long x; } )
        _OPAL_CHECK_SPECIFIC_CXXFLAGS(-Wno-long-double, Wno_long_double, int main () { long double x; })
        _OPAL_CHECK_SPECIFIC_CXXFLAGS(-fstrict-prototype, fstrict_prototype)
        _OPAL_CHECK_SPECIFIC_CXXFLAGS(-Wall, Wall)
    fi

    _OPAL_CHECK_SPECIFIC_CXXFLAGS(-finline-functions, finline_functions)

    # Make sure we can link with the C compiler
    if test "$opal_cv_cxx_compiler_vendor" != "microsoft"; then
      OPAL_LANG_LINK_WITH_C([C++], [],
        [cat <<EOF >&2
**********************************************************************
* It appears that your C++ compiler is unable to link against object
* files created by your C compiler.  This generally indicates either
* a conflict between the options specified in CFLAGS and CXXFLAGS
* or a problem with the local compiler installation.  More
* information (including exactly what command was given to the
* compilers and what error resulted when the commands were executed) is
* available in the config.log file in this directory.
**********************************************************************
EOF
         AC_MSG_ERROR([C and C++ compilers are not link compatible.  Can not continue.])])
    fi

    # If we are on HP-UX, ensure that we're using aCC
    case "$host" in
    *hpux*)
        if test "$BASECXX" = "CC"; then
            AC_MSG_WARN([*** You will probably have problems compiling the MPI 2])
            AC_MSG_WARN([*** C++ bindings with the HP-UX CC compiler.  You should])
            AC_MSG_WARN([*** probably be using the aCC compiler.  Re-run configure])
            AC_MSG_WARN([*** with the environment variable "CXX=aCC".])
        fi
        ;;
    esac

    # Note: gcc-imperonating compilers accept -O3
    if test "$WANT_DEBUG" = "1"; then
        OPTFLAGS=
    else
        if test "$GXX" = yes; then
            OPTFLAGS="-O3"
        else
            OPTFLAGS="-O"
        fi
    fi


    # bool type size and alignment
    AC_CHECK_SIZEOF(bool)
    OPAL_C_GET_ALIGNMENT(bool, OPAL_ALIGNMENT_CXX_BOOL)

    OPAL_ENSURE_CONTAINS_OPTFLAGS("$OPAL_CXXFLAGS_BEFORE_PICKY")
    OPAL_CXXFLAGS_BEFORE_PICKY="$co_result"

    AC_MSG_CHECKING([for CXX optimization flags])
    OPAL_ENSURE_CONTAINS_OPTFLAGS(["$CXXFLAGS"])
    AC_MSG_RESULT([$co_result])
    CXXFLAGS="$co_result"
    OPAL_FLAGS_UNIQ([CXXFLAGS])
    AC_MSG_RESULT(CXXFLAGS result: $CXXFLAGS)
    AC_LANG_POP(C++)
])
