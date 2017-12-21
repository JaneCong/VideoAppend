//
//  LGRender.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGRender.h"
#import <GLKit/GLKit.h>
enum
{
    UNIFORM_SIMPLER,
    NUM_UNIFORMS
};
GLint filetUnforms[NUM_UNIFORMS];

enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBURTES
};
@interface LGRender()
@property CGAffineTransform renderTransform;
@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;
@property GLuint program;
@property GLuint lookUpTexure;
@end

@implementation LGRender
+ (instancetype)sharedRender {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        
    });
    return instance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_currentContext];
        [self setupOffscreenRenderContext];
        NSURL *vertexURL = [[NSBundle mainBundle] URLForResource:@"FilterVertex" withExtension:@"glsl"];
        NSURL *fragURL = [[NSBundle mainBundle] URLForResource:@"FilterFrag" withExtension:@"glsl"];
        [self loadVertexShader:vertexURL AndFragShader:fragURL];
    }
    
    return self;
}

- (void)setupOffscreenRenderContext
{
    //-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Filter Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
}

-(BOOL)loadVertexShader:(NSURL *)vertexURL AndFragShader:(NSURL *)fragURL{
    GLuint vertShader,fragShader;
    _program = glCreateProgram();
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertexURL]) {
        NSLog(@"Filter Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragURL]) {
        NSLog(@"Filter Failed to compile frag shader");
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    
    glAttachShader(_program, fragShader);
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    if (![self linkProgram:_program]) {
        NSLog(@"Filter Faided to link program:%d",_program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    filetUnforms[UNIFORM_SIMPLER] = glGetUniformLocation(_program, "Sampler");

    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Filter Failed to load shader : %@",[error localizedDescription]);
        return NO;
    }
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Filter Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Filter Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


-(void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    if (sourcePixelBuffer) {
        
        CVOpenGLESTextureRef foregroundTexture = [self sourceTextureForPixelBuffer:sourcePixelBuffer];
        CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
        glViewport(0, 0, (GLsizei)CVPixelBufferGetWidth(destinationPixelBuffer), (GLsizei)CVPixelBufferGetHeight(destinationPixelBuffer));
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);//应用FBO渲染到纹理（glGenTextures），直接绘制到纹理中。glCopyTexImage2D是渲染到FrameBuffer->复制FrameBuffer中的像素产生纹理。glFramebufferTexture2D直接渲染生成纹理，做全屏渲染（比如全屏模糊）时比glCopyTexImage2D高效
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Transiton Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        }
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(_program);
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        // texture data varies from 0 -> 1, whereas vertex data varies from -1 -> 1
        GLfloat quadTextureData1 [] = {
            0.5 + quadVertexData1[0]/2, 0.5 + quadVertexData1[1]/2,
            0.5 + quadVertexData1[2]/2, 0.5 + quadVertexData1[3]/2,
            0.5 + quadVertexData1[4]/2, 0.5 + quadVertexData1[5]/2,
            0.5 + quadVertexData1[6]/2, 0.5 + quadVertexData1[7]/2,
        };
        glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
        
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glFlush();
    bail:
        if (foregroundTexture) {
            CFRelease(foregroundTexture);
        }
        
        CFRelease(destTexture);
        // Periodic texture cache flush every frame
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
        [EAGLContext setCurrentContext:nil];
        
    }

}
-(CVOpenGLESTextureRef)sourceTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef sourceTexture = NULL;
    CVReturn err;
    if (!_videoTextureCache) {
        NSLog(@" Filter No video texture cache");
        goto bail;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (int)CVPixelBufferGetWidth(pixelBuffer), (int)CVPixelBufferGetHeight(pixelBuffer), GL_RGBA, GL_UNSIGNED_BYTE, 0, &sourceTexture);
    if (err) {
        NSLog(@"Filter Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
bail:
    return sourceTexture;
}
@end
