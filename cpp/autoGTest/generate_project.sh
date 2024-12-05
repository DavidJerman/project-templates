#!/bin/bash

# Check if cmake and build-essential are installed
echo "Checking if cmake and build-essential are installed..."
if ! command -v cmake &> /dev/null || ! dpkg -l | grep -q build-essential; then
    echo "cmake and/or build-essential are not installed. Installing them now..."
    sudo apt update
    sudo apt install -y cmake build-essential
else
    echo "cmake and build-essential are already installed."
fi

# Prompt the user for the application name
read -p "Enter the application name (APP_NAME): " APP_NAME

# Directories for the project
ROOT_DIR=$(pwd)
SRC_DIR="${ROOT_DIR}/src"
TEST_DIR="${ROOT_DIR}/test"
INCLUDE_DIR="${ROOT_DIR}/include"
EXTERN_DIR="${ROOT_DIR}/extern"

# Initialize Git repository if it doesn't exist
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
else
    echo "Git repository already initialized."
fi

# Ensure the directory structure exists
mkdir -p "${SRC_DIR}" "${TEST_DIR}" "${INCLUDE_DIR}" "${EXTERN_DIR}" "${ROOT_DIR}/samples"

# Add GoogleTest as a git submodule
if [ ! -d "${EXTERN_DIR}/googletest" ]; then
    git submodule add https://github.com/google/googletest.git "${EXTERN_DIR}/googletest"
    git submodule update --init --recursive
fi

# Generate the top-level CMakeLists.txt
cat <<EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.21)
set(APP_NAME "${APP_NAME}")
set(TEST_NAME "\${APP_NAME}Test")
set(LIB_NAME "\${APP_NAME}Lib")
project(\${APP_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")

set(PROJECT_ROOT \${CMAKE_CURRENT_SOURCE_DIR})
set(INCLUDE_DIR \${PROJECT_ROOT}/include)
set(SRC_DIR \${PROJECT_ROOT}/src)
set(TEST_DIR \${PROJECT_ROOT}/test)
set(EXTERN_DIR \${PROJECT_ROOT}/extern)

add_subdirectory(src)
add_subdirectory(test)

file(GLOB SAMPLE_FILES "\${PROJECT_ROOT}/samples/*.txt")
file(COPY \${SAMPLE_FILES} DESTINATION \${CMAKE_BINARY_DIR}/samples)
EOF

echo "Generated CMakeLists.txt"

# Generate src/CMakeLists.txt
mkdir -p src
cat <<EOF > src/CMakeLists.txt
cmake_minimum_required(VERSION 3.21)

file(GLOB_RECURSE SRC_FILES "\${SRC_DIR}/*.cpp")
list(REMOVE_ITEM SRC_FILES "\${SRC_DIR}/main.cpp")

add_library(\${LIB_NAME} \${SRC_FILES})

target_include_directories(\${LIB_NAME} PUBLIC \${INCLUDE_DIR})

add_executable(\${APP_NAME} \${SRC_DIR}/main.cpp)

target_link_libraries(\${APP_NAME} \${LIB_NAME})
EOF

echo "Generated src/CMakeLists.txt"

# Create a sample main.cpp in src/
cat <<EOF > "${SRC_DIR}/main.cpp"
#include <iostream>

int main() {
    std::cout << "Welcome to ${APP_NAME}!" << std::endl;
    return 0;
}
EOF

echo "Generated src/main.cpp"

# Create a temporary lib cpp file in src
touch "${SRC_DIR}/tmp.cpp"

echo "Generated src/tmp.cpp"

# Generate test/CMakeLists.txt
mkdir -p test
cat <<EOF > test/CMakeLists.txt
add_subdirectory(\${EXTERN_DIR}/googletest googletest-build)

file(GLOB_RECURSE TEST_FILES "\${TEST_DIR}/*.cpp")

add_executable(\${TEST_NAME} \${TEST_FILES})

target_include_directories(\${TEST_NAME} PRIVATE \${INCLUDE_DIR})

target_link_libraries(\${TEST_NAME} PRIVATE \${LIB_NAME} gtest gtest_main)
EOF

echo "Generated test/CMakeLists.txt"

# Create a test example in test/
cat <<EOF > "${TEST_DIR}/test_example.cpp"
#include <gtest/gtest.h>

// Test Case: Check if the add function works correctly
TEST(AdditionTest, HandlesPositiveNumbers) {
    EXPECT_EQ(3, 3);
}

TEST(AdditionTest, HandlesNegativeNumbers) {
    EXPECT_EQ(-3, -3);
}

TEST(AdditionTest, HandlesMixedSignNumbers) {
    EXPECT_EQ(0, 0);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
EOF

echo "Generated test/text_example.cpp"

# Create .gitignore to exclude files and folders from git tracking
cat <<EOF > .gitignore
# Build folders
*-build-*
build

# IDE config files
.idea
.vscode
.vs

# Node modules
node_modules

# GoogleTest build directory
googletest-build
EOF

echo "Generated .gitignore"

# Inform user of completion
echo "Project structure with GoogleTest has been created successfully!"

# Ask the user if they want to perform a test
read -p "Do you want to perform a test? (y/n): " perform_test
if [[ "$perform_test" =~ ^[Yy]$ ]]; then
    echo "Running the build process and tests..."

    # Run cmake and build the project
    cmake -S . -B build
    cd build && make

    # Run the tests and the main application
    ./test/${APP_NAME}Test
    ./src/${APP_NAME}
else
    echo "You can perform the test later using the following commands:"
    echo "  cmake -S . -B build"
    echo "  cd build && make"
    echo "  ./test/\${APP_NAME}Test"
    echo "  ./src/\${APP_NAME}"
fi
