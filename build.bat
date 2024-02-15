@echo off

echo ------------------------------ 
echo Build andorid application
echo ------------------------------ 

set PLATFORM=%ANDROID_HOME%/platforms/android-29
set BUILD_TOOLS=%ANDROID_HOME%/build-tools/29.0.3
set NDK=%ANDROID_HOME%/ndk/26.2.11394342

echo - Compiling resources files 
call %BUILD_TOOLS%/aapt2 compile -v --dir ./res -o ./obj/res.zip

echo - Linking resources files into APK 
call %BUILD_TOOLS%/aapt2 link obj/res.zip^
                         -o ./bin/game.unaligned.apk^
                         -I %PLATFORM%/android.jar^
                         --manifest ./AndroidManifest.xml^
                         --java ./src 2>NUL
rem TODO: have to redirect stderror to NUL in order to disable a warning telling that resources.arsc in the APK is compressed.

echo - Compile java code to bytecode
javac -Xlint:-options -source 1.8 -target 1.8 -bootclasspath %PLATFORM%/android.jar src/com/tomas/game/*.java -d obj

echo - Compile java bytecode into Dalvik Executable file 'classes.dex'
call %BUILD_TOOLS%/d8 obj/com/tomas/game/*.class --output . --lib %PLATFORM%/android.jar --classpath ./obj/

echo - Add the 'calsses.dex' to APK
call %BUILD_TOOLS%/aapt add bin/game.unaligned.apk classes.dex

echo ------------------------------ 
echo Compile Native C code 
echo ------------------------------ 

set TARGET=libgame.so
set SONAME=-Wl,-soname,%TARGET%
set CC=%NDK%/toolchains\llvm\prebuilt\windows-x86_64\bin\clang
set CFLAGS=-pedantic -Wall -Wextra -Werror -std=c11 -g 
set LIBS=-lGLESv3
set SOURCES=./src/native/native.c
set INC_DIR=-I%NDK%/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include  -I./src/native
set LIB_DIR=-L%NDK%/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib -L%NDK%/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/aarch64-linux-android
rem TODO: Maybe sysroot includes and libpaths are already define in the NDK clang compiler

%CC% %CFLAGS% %INC_DIR% -target aarch64-linux-android29 -shared -o %TARGET% %SOURCES% %SONAME% %LIB_DIR% %LIBS%

echo - Add the 'libgame.so' to APK
call %BUILD_TOOLS%/aapt add bin/game.unaligned.apk libgame.so 

echo ------------------------------ 
echo Prepare the final APK 
echo ------------------------------ 

echo - Align the apk
call %BUILD_TOOLS%/zipalign -f 4 ./bin/game.unaligned.apk ./bin/game.apk

echo - Sign the apk
call %BUILD_TOOLS%/apksigner sign --ks-pass pass:%TEST_ANDROID_PASSWORD% --ks mykey.keystore ./bin/game.apk
