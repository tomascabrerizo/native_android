#include <stdlib.h>
#include <assert.h>

#include <jni.h>
#include <GLES3/gl3.h>

#include <android/log.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

#define logd(tag, ...) __android_log_print(ANDROID_LOG_DEBUG, tag, __VA_ARGS__)

unsigned int gpu_create_program(const char *vert_src, const char *frag_src) {

    unsigned int vert_shader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vert_shader, 1, &vert_src, 0);
    glCompileShader(vert_shader);
    int success;
    char info[512];
    glGetShaderiv(vert_shader, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(vert_shader, 512, 0, info);
        logd("Game", "[Vertex Shader] %s\n", info);
    }

    unsigned int frag_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(frag_shader, 1, &frag_src, 0);
    glCompileShader(frag_shader);
    glGetShaderiv(frag_shader, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(frag_shader, 512, 0, info);
        logd("Game", "[Fragment Shader] %s\n", info);
    }

    unsigned int program = glCreateProgram();
    glAttachShader(program, vert_shader);
    glAttachShader(program, frag_shader);
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if(!success) {
        glGetProgramInfoLog(program, 512, 0, info);
        logd("Game", "[Program] %s\n", info);
    }
    glDeleteShader(vert_shader);
    glDeleteShader(frag_shader);

    return program;
}

jobject *asset_manager_ref   = 0;
AAssetManager *asset_manager = 0;

float vertices[] = { -0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 0.5f, -0.5f, 0.0f,
                     0.0f,  1.0f,  0.0f, 0.0f, 0.5f, 0.0f, 0.0f, 0.0f,  1.0f };

unsigned int program;
unsigned int vao, vbo;

void gpu_init(void) {
    const char *version = (const char *)glGetString(GL_VERSION);
    logd("Game", "OpenGL initialized: %s", version);

    AAsset *vert_asset = AAssetManager_open(asset_manager, "shader.vert", AASSET_MODE_BUFFER);
    AAsset *frag_asset = AAssetManager_open(asset_manager, "shader.frag", AASSET_MODE_BUFFER);

    char *vert_src = (char *)AAsset_getBuffer(vert_asset);
    char *frag_src = (char *)AAsset_getBuffer(frag_asset);

    program = gpu_create_program(vert_src, frag_src);

    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);

    glBindVertexArray(vao);

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *)0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void gpu_render(void) {
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(program);
    glBindVertexArray(vao);
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

void gpu_update(float dt) {
    (void)dt;
    // logd("Game", "dt:%f\n", dt);
}

void gpu_viewport(int x, int y, int w, int h) {
    glViewport(x, y, w, h);
}

JNIEXPORT void JNICALL Java_com_tomas_game_GameRenderer_gpuInit(JNIEnv *env, jobject *thiz,
                                                                jobject *manager) {
    (void)thiz;
    asset_manager_ref = (*env)->NewLocalRef(env, manager);
    asset_manager     = AAssetManager_fromJava(env, asset_manager_ref);
    assert(asset_manager_ref);
    assert(asset_manager);
    gpu_init();
}

JNIEXPORT void JNICALL Java_com_tomas_game_GameRenderer_gpuRender(JNIEnv *env, jobject *thiz) {
    (void)env;
    (void)thiz;
    gpu_render();
}

JNIEXPORT void JNICALL Java_com_tomas_game_GameRenderer_gpuUpdate(JNIEnv *env, jobject *thiz,
                                                                  jfloat dt) {
    (void)env;
    (void)thiz;
    gpu_update(dt);
}

JNIEXPORT void JNICALL Java_com_tomas_game_GameRenderer_gpuSetViewport(JNIEnv *env, jobject *thiz,
                                                                       jint x, jint y, jint w,
                                                                       jint h) {
    (void)env;
    (void)thiz;
    gpu_viewport(x, y, w, h);
}
