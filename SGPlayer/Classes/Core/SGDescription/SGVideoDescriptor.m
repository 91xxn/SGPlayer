//
//  SGVideoDescriptor.m
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDescriptor.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"

@implementation SGVideoDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    SGVideoDescriptor *obj = [[SGVideoDescriptor alloc] init];
    obj->_format = self->_format;
    obj->_cv_format = self->_cv_format;
    obj->_width = self->_width;
    obj->_height = self->_height;
    obj->_colorspace = self->_colorspace;
    obj->_sampleAspectRatio = self->_sampleAspectRatio;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_format = AV_PIX_FMT_NONE;
        self->_cv_format = SGPixelFormatFF2AV(self->_format);
        self->_width = 0;
        self->_height = 0;
        self->_colorspace = AVCOL_SPC_RGB;
        self->_sampleAspectRatio = (SGRational){0, 1};
    }
    return self;
}

- (instancetype)initWithFrame:(AVFrame *)frame
{
    if (self = [super init]) {
        self->_format = frame->format;
        self->_cv_format = SGPixelFormatFF2AV(self->_format);
        self->_width = frame->width;
        self->_height = frame->height;
        self->_colorspace = frame->colorspace;
        SGRational sar = {
            frame->sample_aspect_ratio.num,
            frame->sample_aspect_ratio.den,
        };
        self->_sampleAspectRatio = sar;
    }
    return self;
}

- (void)setFormat:(int)format
{
    self->_format = format;
    self->_cv_format = SGPixelFormatFF2AV(format);
}

- (void)setCv_format:(OSType)cv_format
{
    self->_format = SGPixelFormatAV2FF(cv_format);
    self->_cv_format = cv_format;
}

- (SGRational)frameSize
{
    return (SGRational){self->_width, self->_height};
}

- (SGRational)presentationSize
{
    int width = self->_width;
    int height = self->_height;
    AVRational aspectRatio = {
        self->_sampleAspectRatio.num,
        self->_sampleAspectRatio.den,
    };
    if (av_cmp_q(aspectRatio, av_make_q(0, 1)) <= 0) {
        aspectRatio = av_make_q(1, 1);
    }
    aspectRatio = av_mul_q(aspectRatio, av_make_q(width, height));
    if (av_q2d(aspectRatio) >= 1) {
        width = av_rescale(height, aspectRatio.num, aspectRatio.den) & ~1;
    } else {
        height = av_rescale(width, aspectRatio.den, aspectRatio.num) & ~1;
    }
    return (SGRational){width, height};
}

- (BOOL)isEqualToDescriptor:(SGVideoDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    return
    self->_format == descriptor->_format &&
    self->_cv_format == descriptor->_cv_format &&
    self->_width == descriptor->_width &&
    self->_height == descriptor->_height &&
    self->_colorspace == descriptor->_colorspace &&
    self->_sampleAspectRatio.num == descriptor->_sampleAspectRatio.num &&
    self->_sampleAspectRatio.den == descriptor->_sampleAspectRatio.den;
}

@end
