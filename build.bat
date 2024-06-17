@echo off

echo ------------------------------ 
echo Build andorid application
echo ------------------------------ 

if exist bin (
    rmdir /s /q bin
)
mkdir bin

set PLATFORM=%ANDROID_HOME%/platforms/android-29
set BUILD_TOOLS=%ANDROID_HOME%/build-tools/29.0.3
set NDK=%ANDROID_HOME%/ndk/26.2.11394342

echo - Compiling resources files 
call %BUILD_TOOLS%/aapt2 compile -v --dir ./res -o ./obj/res.zip

echo - Linking resources files into APK 
call %BUILD_TOOLS%/aapt2 link obj/res.zip^
                         -o ./bin/game.unaligned.apk^
                         -I %PLATFORM%/android.jar^
                         -A ./assets^
                         --manifest ./AndroidManifest.xml^
                         --java ./src

rem %BUILD_TOOLS%/aapt package -f -m -F ./bin/game.unaligned.apk^
rem                           -J ./src^
rem                           -S ./res^
rem                           -A ./assets^
rem                           -M ./AndroidManifest.xml -I %PLATFORM%/android.jar

echo - Compile java code to bytecode
javac -Xlint:-options -source 1.8 -target 1.8 -bootclasspath %PLATFORM%/android.jar src/com/tomas/game/*.java -d obj

echo - Compile java bytecode into Dalvik Executable file 'classes.dex'
call %BUILD_TOOLS%/d8 obj/com/tomas/game/*.class --output . --lib %PLATFORM%/android.jar --classpath ./obj/

echo - Add the 'calsses.dex' to APK
call %BUILD_TOOLS%/aapt add bin/game.unaligned.apk classes.dex

echo ------------------------------ 
echo Compile Native C code 
echo ------------------------------ 

set SYSROOT=%NDK%/toolchains/llvm/prebuilt/windows-x86_64/sysroot

set TARGET=libgame.so
set ARCH=arm64-v8a
set SONAME=-Wl,-soname,%TARGET%
set CC=%NDK%/toolchains\llvm\prebuilt\windows-x86_64\bin\clang
set CFLAGS=-pedantic -Wall -Wextra -Werror -std=c11 -g -fPIC -MD -MT -DANDROID
set LIBS=-llog -lEGL -lGLESv3
set SOURCES=./src/native/native.c
set INC_DIR=-I./src/native
set LIB_DIR=
set OUP_DIR=lib/%ARCH%
rem TODO: Maybe sysroot includes and libpaths are already define in the NDK clang compiler

if exist lib (
    rmdir /s /q lib
)
mkdir lib
mkdir lib\%ARCH%

call %CC% --target=aarch64-none-linux-android29 -shared -fPIC -o %OUP_DIR%/%TARGET% %SOURCES% %SONAME% %LIB_DIR% %LIBS%

echo - Add the 'libgame.so' to APK
call %BUILD_TOOLS%/aapt add bin/game.unaligned.apk %OUP_DIR%/%TARGET%

echo ------------------------------ 
echo Prepare the final APK 
echo ------------------------------ 

echo - Align the apk
call %BUILD_TOOLS%/zipalign -f 4 ./bin/game.unaligned.apk ./bin/game.apk

echo - Sign the apk
call %BUILD_TOOLS%/apksigner sign --ks-pass pass:%TEST_ANDROID_PASSWORD% --ks mykey.keystore ./bin/game.apk

rem install the apk
call run.bat