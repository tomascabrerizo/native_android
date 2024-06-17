package com.tomas.game;

import android.opengl.GLSurfaceView.Renderer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

class GameRenderer implements Renderer {

    public native void gpuInit();

    public native void gpuRender();

    public native void gpuUpdate(float dt);

    public native void gpuSetViewport(int x, int y, int w, int h);

    private static final double NANOS_PER_SECOND = 1000000000.0;
    private double lastTime;

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        gpuInit();
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        gpuSetViewport(0, 0, width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        long currentTime = System.nanoTime();
        double dt = (currentTime - lastTime) / NANOS_PER_SECOND;
        lastTime = currentTime;

        gpuUpdate((float) dt);
        gpuRender();
    }

}