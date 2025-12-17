#!/bin/bash

# 1. Ask for Project Name
read -p "Enter the project name: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="OptimisationProblems"
fi

# 2. Detect Clang and Ninja
CMAKE_ARGS=""
if command -v clang++ >/dev/null 2>&1; then
    echo "Using Clang compiler..."
    export CC=clang
    export CXX=clang++
fi

if command -v ninja >/dev/null 2>&1; then
    echo "Ninja build system detected. Using Ninja..."
    CMAKE_ARGS="-G Ninja"
else
    echo "Ninja not found. Defaulting to Make..."
fi

# 3. Directories
ROOT_DIR=$(pwd)
SRC_DIR="${ROOT_DIR}/src"
INCLUDE_DIR="${ROOT_DIR}/include"
TEST_DIR="${ROOT_DIR}/tests"

mkdir -p "${SRC_DIR}" "${INCLUDE_DIR}" "${TEST_DIR}"

# 4. Create the requested CMakeLists.txt 
cat <<EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.31)
project(${PROJECT_NAME})

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -fsanitize=address,undefined")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Main app
include_directories(include)

file(GLOB_RECURSE SOURCES "src/*.cpp" "include/*.h")

add_executable(${PROJECT_NAME} \${SOURCES})

# Google tests 
include(FetchContent)

FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/releases/download/v1.17.0/googletest-1.17.0.tar.gz
)

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(googletest)

enable_testing()

file(GLOB_RECURSE TEST_SOURCES "tests/*.cpp")

set(TEST_SOURCES_EXCLUDE_MAIN "")
foreach(src \${SOURCES})
    if(NOT src MATCHES "main\\.cpp$")
        list(APPEND TEST_SOURCES_EXCLUDE_MAIN \${src})
    endif()
endforeach()

add_executable(${PROJECT_NAME}Tests \${TEST_SOURCES} \${TEST_SOURCES_EXCLUDE_MAIN})

target_link_libraries(${PROJECT_NAME}Tests gtest_main)

include(GoogleTest)
gtest_discover_tests(${PROJECT_NAME}Tests)
EOF

# 5. Create main.cpp
cat <<EOF > "${SRC_DIR}/main.cpp"
#include <iostream>

int main() {
    std::cout << "Starting ${PROJECT_NAME}..." << std::endl;
    return 0;
}
EOF

# 6. Create Google Test file
cat <<EOF > "${TEST_DIR}/test_main.cpp"
#include <gtest/gtest.h>

TEST(InitialTest, HelloWorld) {
    EXPECT_EQ(1, 1);
}
EOF

# 7. Automated Build & Test
echo "Building project with CMake..."
cmake -S . -B build $CMAKE_ARGS
cmake --build build

echo "--------------------------------------"
echo "Project ${PROJECT_NAME} is ready."
echo "Binary location: ./build/${PROJECT_NAME}"
echo "Test location: ./build/${PROJECT_NAME}Tests"
