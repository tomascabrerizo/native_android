@echo off

set PLATFORM=%ANDROID_HOME%/platforms/android-29
set BUILD_TOOLS=%ANDROID_HOME%/build-tools/29.0.3

echo Setup Resorces
%BUILD_TOOLS%/aapt package -f -m -J ./src -M ./AndroidManifest.xml -S ./res  -I %PLATFORM%/android.jar

echo Compile java code to bytecode
javac -d obj -classpath src -classpath %PLATFORM%/android.jar src/com/tomas/game/*.java

echo Compile java bytecode into Dalvik Executable file 'classes.dex'
call %BUILD_TOOLS%/d8 obj/com/tomas/game/*.class --output . --lib %PLATFORM%/android.jar --classpath ./obj/

echo Make apk file
%BUILD_TOOLS%/aapt package -f -m -F ./bin/game.unaligned.apk -M ./AndroidManifest.xml -S ./res -I %PLATFORM%/android.jar

echo Add the compile code to APK
call %BUILD_TOOLS%/aapt add bin/game.unaligned.apk classes.dex

echo Align the apk
call %BUILD_TOOLS%/zipalign -f 4 ./bin/game.unaligned.apk ./bin/game.apk

echo Sign the apk
call %BUILD_TOOLS%/apksigner sign --ks-pass pass:%TEST_ANDROID_PASSWORD% --ks mykey.keystore ./bin/game.apk
