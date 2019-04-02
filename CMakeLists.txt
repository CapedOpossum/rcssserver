cmake_minimum_required(VERSION 3.12)

project(rcssserver
    VERSION "15.5.1"
    DESCRIPTION "RoboCup Simulated Soccer Server"
    HOMEPAGE_URL "https://rcsoccersim.github.io"
)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules" CACHE PATH "Directory of CMake modules.")

find_package(FLEX REQUIRED)
find_package(BISON REQUIRED)
find_package(Boost "1.32.0" REQUIRED COMPONENTS "filesystem")
find_package(AWK REQUIRED)

include(CheckIncludeFileCXX)
include(CheckTypeSize)
check_include_file_cxx("sys/socket.h" HAVE_SYS_SOCKET_H)
check_include_file_cxx("sys/param.h" HAVE_SYS_PARAM_H)
check_include_file_cxx("sys/time.h" HAVE_SYS_TIME_H)
check_include_file_cxx("netinet/in.h" HAVE_NETINET_IN_H)
check_include_file_cxx("arpa/inet.h" HAVE_ARPA_INET_H)
check_include_file_cxx("netdb.h" HAVE_NETDB_H)
check_include_file_cxx("unistd.h" HAVE_UNISTD_H)
check_include_file_cxx("poll.h" HAVE_POLL_H)
check_include_file_cxx("pwd.h" HAVE_PWD_H)
check_include_file_cxx("sstream" HAVE_SSTREAM)

if (HAVE_SYS_SOCKET_H)
    set(old_CMAKE_EXTRA_INCLUDE_FILES "${CMAKE_EXTRA_INCLUDE_FILES}")
    set(CMAKE_EXTRA_INCLUDE_FILES "sys/socket.h")
    check_type_size("socklen_t" SOCKLEN_T LANGUAGE CXX)
    set(CMAKE_EXTRA_INCLUDE_FILES "${old_CMAKE_EXTRA_INCLUDE_FILES}")
    unset(old_CMAKE_EXTRA_INCLUDE_FILES)
endif ()

configure_file(
    "${PROJECT_SOURCE_DIR}/config.h.in"
    "${PROJECT_BINARY_DIR}/config.h"
    @ONLY
)

include_directories(
    "${PROJECT_BINARY_DIR}"
)

add_compile_definitions("HAVE_CONFIG_H=1" "VERSION=\"${PROJECT_VERSION}\"")

# ==============================================================================
# RCSS Configuration Parser Library Build Plan
# ==============================================================================
add_library(rcssconfparser SHARED
    "rcssbase/conf/parser.cpp"
    "rcssbase/conf/builder.cpp"
    "rcssbase/conf/statushandler.cpp"
    "rcssbase/conf/streamstatushandler.cpp"
	"rcssbase/conf/builder.hpp"
	"rcssbase/conf/parser.hpp"
	"rcssbase/conf/paramgetter.hpp"
	"rcssbase/conf/paramsetter.hpp"
	"rcssbase/conf/statushandler.hpp"
    "rcssbase/conf/streamstatushandler.hpp"
)

set_target_properties(
    rcssconfparser PROPERTIES
        SOVERSION "3.0.0"
        VERSION "${PROJECT_VERSION}"
)

target_link_libraries(
    rcssconfparser
        PUBLIC
            Boost::boost
            Boost::filesystem
)

target_include_directories(
    rcssconfparser
        PUBLIC
            "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>"
)

target_compile_features(
    rcssconfparser
        PUBLIC
            cxx_std_14
)

# ==============================================================================
# RCSS GZip Compression Library Build Plan
# ==============================================================================
add_library(rcssgz SHARED
    "rcssbase/gzip/gzfstream.hpp"
    "rcssbase/gzip/gzfstream.cpp"
    "rcssbase/gzip/gzstream.hpp"
    "rcssbase/gzip/gzstream.cpp"
)

set_target_properties(
    rcssgz PROPERTIES
        SOVERSION "1.0.0"
        VERSION "${PROJECT_VERSION}"
)

target_compile_features(
    rcssgz
        PUBLIC
            cxx_std_14
)

# ==============================================================================
# RCSS Network Library Build Plan
# ==============================================================================
add_library(rcssnet SHARED
    "rcssbase/net/addr.cpp"
    "rcssbase/net/socket.cpp"
    "rcssbase/net/socketstreambuf.cpp"
    "rcssbase/net/udpsocket.cpp"
    "rcssbase/net/tcpsocket.cpp"
    "rcssbase/net/addr.hpp"
    "rcssbase/net/socket.hpp"
    "rcssbase/net/udpsocket.hpp"
    "rcssbase/net/tcpsocket.hpp"
    "rcssbase/net/socketstreambuf.hpp"
    "rcssbase/net/isocketstream.hpp"
    "rcssbase/net/osocketstream.hpp"
    "rcssbase/net/iosocketstream.hpp"
)

set_target_properties(
    rcssnet PROPERTIES
        SOVERSION "1.1.0"
        VERSION "${PROJECT_VERSION}"
)

target_include_directories(
    rcssnet
        PUBLIC
            "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>"
)

target_compile_features(
    rcssnet
        PUBLIC
            cxx_std_14
)

# ==============================================================================
# RCSS Coach Language Library Build Plan
# ==============================================================================
bison_target(rcss_clang_parser
    "src/coach_lang_parser.ypp"
    "${PROJECT_BINARY_DIR}/src/coach_lang_parser.cpp"
    COMPILE_FLAGS "-d"
)

flex_target(rcss_clang_scanner
    "src/coach_lang_tok.lpp"
    "${PROJECT_BINARY_DIR}/src/clang_scanner/lex.yy.c"
)

add_flex_bison_dependency(rcss_clang_scanner rcss_clang_parser)

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/src/coach_lang_tok.cpp"
    COMMAND "${CMAKE_COMMAND}"
    ARGS
        "-DAWK_BIN=${AWK_BIN}"
        "-DAWK_SCRIPT=${PROJECT_SOURCE_DIR}/src/flex_cpp_adapt.awk"
        "-DFILE_BASE_NAME=coach_lang_tok"
        "-DINPUT_FILE=${PROJECT_BINARY_DIR}/src/clang_scanner/lex.yy.c"
        "-DOUTPUT_FILE=${PROJECT_BINARY_DIR}/src/coach_lang_tok.cpp"
        "-P" "${PROJECT_SOURCE_DIR}/src/flex_cpp_adapt.cmake"
    MAIN_DEPENDENCY
        "${PROJECT_BINARY_DIR}/src/clang_scanner/lex.yy.c"
)

add_library(rcssclangparser SHARED
    "src/clangbuilder.cpp"
    "src/clangmsgbuilder.cpp"
    "src/clangparser.cpp"
    "src/clangmsg.cpp"
    "src/clangmetamsg.cpp"
    "src/clangfreeformmsg.cpp"
    "src/clangunsuppmsg.cpp"
    "src/clangrulemsg.cpp"
    "src/clangdelmsg.cpp"
    "src/clanginfomsg.cpp"
    "src/clangadvicemsg.cpp"
    "src/clangdefmsg.cpp"
    "src/clangaction.cpp"
    "src/clangutil.cpp"
    "src/coach_lang_comp.cpp"
    "src/arithop.cpp"
    "src/cond.cpp"
    "src/compop.cpp"
    "src/region.cpp"
    "src/rule.cpp"
    "src/rcssexceptions.cpp"
    "${PROJECT_BINARY_DIR}/src/coach_lang_parser.cpp"
    "${PROJECT_BINARY_DIR}/src/coach_lang_tok.cpp"
)

target_include_directories(
    rcssclangparser
        PUBLIC
            "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>"
        PRIVATE
            "${PROJECT_SOURCE_DIR}/src"
)

target_compile_features(
    rcssclangparser
        PUBLIC
            cxx_std_14
)

# ==============================================================================
# RCSS Server Build Plan
# ==============================================================================
bison_target(player_command_parser
    "src/player_command_parser.ypp"
    "${PROJECT_BINARY_DIR}/src/player_command_parser.cpp"
    COMPILE_FLAGS "-d"
)

flex_target(player_command_scanner
    "src/player_command_tok.lpp"
    "${PROJECT_BINARY_DIR}/src/lex.yy.c"
)

add_flex_bison_dependency(rcss_clang_scanner rcss_clang_parser)

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/src/player_command_tok.cpp"
    COMMAND "${CMAKE_COMMAND}"
    ARGS
        "-DAWK_BIN=${AWK_BIN}"
        "-DAWK_SCRIPT=${PROJECT_SOURCE_DIR}/src/flex_cpp_adapt.awk"
        "-DFILE_BASE_NAME=player_command_tok"
        "-DINPUT_FILE=${PROJECT_BINARY_DIR}/src/lex.yy.c"
        "-DOUTPUT_FILE=${PROJECT_BINARY_DIR}/src/player_command_tok.cpp"
        "-P" "${PROJECT_SOURCE_DIR}/src/flex_cpp_adapt.cmake"
    MAIN_DEPENDENCY
        "${PROJECT_BINARY_DIR}/src/lex.yy.c"
)

add_executable(rcssserver
    "src/audio.cpp"
    "src/bodysender.cpp"
    "src/coach.cpp"
    "src/csvsaver.cpp"
    "src/dispsender.cpp"
    "src/field.cpp"
    "src/fullstatesender.cpp"
    "src/heteroplayer.cpp"
    "src/initsender.cpp"
    "src/initsendercoach.cpp"
    "src/initsenderlogger.cpp"
    "src/initsendermonitor.cpp"
    "src/initsenderonlinecoach.cpp"
    "src/initsenderplayer.cpp"
    "src/landmarkreader.cpp"
    "src/logger.cpp"
    "src/main.cpp"
    "src/monitor.cpp"
    "src/pcombuilder.cpp"
    "src/pcomparser.cpp"
    "src/player.cpp"
    "src/playerparam.cpp"
    "src/object.cpp"
    "src/referee.cpp"
    "src/remoteclient.cpp"
    "src/resultsaver.cpp"
    "src/serializer.cpp"
    "src/serializercoachstdv1.cpp"
    "src/serializercoachstdv7.cpp"
    "src/serializercoachstdv8.cpp"
    "src/serializercoachstdv13.cpp"
    "src/serializercoachstdv14.cpp"
    "src/serializercommonstdv1.cpp"
    "src/serializercommonstdv7.cpp"
    "src/serializercommonstdv8.cpp"
    "src/serializermonitor.cpp"
    "src/serializeronlinecoachstdv1.cpp"
    "src/serializeronlinecoachstdv6.cpp"
    "src/serializeronlinecoachstdv7.cpp"
    "src/serializeronlinecoachstdv8.cpp"
    "src/serializeronlinecoachstdv13.cpp"
    "src/serializeronlinecoachstdv14.cpp"
    "src/serializerplayerstdv1.cpp"
    "src/serializerplayerstdv7.cpp"
    "src/serializerplayerstdv8.cpp"
    "src/serializerplayerstdv13.cpp"
    "src/serializerplayerstdv14.cpp"
    "src/serverparam.cpp"
    "src/stadium.cpp"
    "src/stdoutsaver.cpp"
    "src/stdtimer.cpp"
    "src/synctimer.cpp"
    "src/team.cpp"
    "src/utility.cpp"
    "src/visualsendercoach.cpp"
    "src/visualsenderplayer.cpp"
    "src/weather.cpp"
    "src/xmlreader.cpp"
    "src/xpmholder.cpp"
    "${PROJECT_BINARY_DIR}/src/player_command_parser.cpp"
    "${PROJECT_BINARY_DIR}/src/player_command_tok.cpp"
)

target_include_directories(
    rcssserver
        PRIVATE
            "${PROJECT_SOURCE_DIR}"
            "${PROJECT_SOURCE_DIR}/src"
)

target_link_libraries(rcssserver
    rcssclangparser
    rcssconfparser
    rcssnet
    rcssgz
    Boost::filesystem
    Boost::boost
)

target_compile_definitions(
    rcssserver
        PRIVATE
            "PACKAGE=\"${PROJECT_NAME}\""
)

target_compile_features(
    rcssserver
        PRIVATE
            cxx_std_14
)
