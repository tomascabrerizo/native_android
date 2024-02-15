cmake_minimum_required(VERSION 3.5.0)

project(GameInC)

add_library(game SHARED src/native/native.c)

include_directories(src/native/)
