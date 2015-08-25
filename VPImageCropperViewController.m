//
//  VPImageCropperViewController.m
//  VPolor
//
//  Created by Vinson.D.Warm on 12/30/13.
//  Copyright (c) 2013 Huang Vinson. All rights reserved.
//

#import "VPImageCropperViewController.h"
#import "CLImageEditor.h"
#import "CLRotateTool.h"
#import "CLClippingTool.h"

#define SCALE_FRAME_Y 100.0f
#define BOUNDCE_DURATION 0.3f

@implementation UIView (NYX_Screenshot)

-(UIImage*)imageByRenderingView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface VPImageCropperViewController ()

@property (nonatomic, retain) UIImage *originalImage;
@property (nonatomic, retain) UIImage *editedImage;

@property (nonatomic, retain) UIImageView *showImgView;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic, retain) UIView *ratioView;

@property (nonatomic, assign) CGRect oldFrame;
@property (nonatomic, assign) CGRect largeFrame;
@property (nonatomic, assign) CGFloat limitRatio;
@property (nonatomic, assign) CGRect latestFrame;

// alvin
@property (nonatomic, assign) BOOL isShowAllPic;
@property (nonatomic, strong) UIButton *rotateButton;
@property (nonatomic, strong) UIButton *clipButton;
@property (nonatomic, assign) CGRect imageViewOldFrame;
@property (nonatomic, assign) int numberRotate;
@property (nonatomic, strong) UIView *finalView; // 用view来截图
@end

@implementation VPImageCropperViewController

- (void)dealloc {
    self.originalImage = nil;
    self.showImgView = nil;
    self.editedImage = nil;
    self.overlayView = nil;
    self.ratioView = nil;
    self.finalView = nil;
}

- (id)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio {
    self = [super init];
    if (self) {
        self.cropFrame = cropFrame;
        self.limitRatio = limitRatio;
        self.originalImage = [self fixOrientation:originalImage];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // alvin 添加导航栏
    self.title = @"编辑";
    self.isShowAllPic = NO;
    self.numberRotate = 1;
    
    // 自定义back按钮
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back-white"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStylePlain target:self action:@selector(nextAction)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    self.navigationItem.rightBarButtonItem = rightBtn;
    
    
    [self initView];
    [self initControlBtn];
    [self showClipPic];
}

#pragma mark - alvin
- (void)back:(UIBarButtonItem *)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageCropperDidCancel:)]) {
        [self.delegate imageCropperDidCancel:self];
    }
    [D_Main_Appdelegate showPreView];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextAction{
    
//    if (self.delegate && [self.delegate respondsToSelector:@selector(imageCropper:didFinished:)]) {
//        [self.delegate imageCropper:self didFinished:[self getSubImage]];
//    }
//    UIImageWriteToSavedPhotosAlbum([self getSubImageByAlvin], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    NSArray *toolNames = @[NSStringFromClass([CLRotateTool class]),NSStringFromClass([CLClippingTool class])];
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:[self getSubImageByAlvin] toolArr:toolNames isFirstEditor:NO];
    editor.toCustomerID = self.toCustomerID;
    editor.mobileBookID = self.mobileBookID;
    editor.toName = self.toName;
    [self.navigationController pushViewController:editor animated:YES];//
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{}

// showAllPic
- (void)showAllPic{
    
    self.imageViewOldFrame = self.showImgView.frame;
    CGRect frame = self.showImgView.frame;
    CGFloat roti = frame.size.height/frame.size.width;
    if (roti>=1) {
        if (frame.size.height >= Screen_width) {
            frame.size.height = Screen_width;
            frame.size.width = (Screen_width)/roti;
        }
    }else{
        if (frame.size.width > Screen_width) {
            frame.size.width = Screen_width;
            frame.size.height = Screen_width*roti;
        }
    }
    self.showImgView.frame = frame;
    self.showImgView.center = self.ratioView.center;
}

- (void)showClipPic{

//    self.showImgView.frame = self.imageViewOldFrame;
    
    CGRect frame = self.showImgView.frame;
    CGFloat roti = frame.size.height/frame.size.width;
    if (roti>=1) {
        if (frame.size.width <= Screen_width) {
            frame.size.width = Screen_width;
            frame.size.height = (Screen_width)*roti;
        }
    }else{
        if (frame.size.height <= Screen_width) {
            frame.size.height = Screen_width;
            frame.size.width = Screen_width/roti;
        }
    }
    self.showImgView.frame = frame;
    self.showImgView.center = self.ratioView.center;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (void)initView {
    self.view.backgroundColor = COLOR_MAIN_WHITE;
    
    self.finalView = [[UIView alloc] initWithFrame:self.cropFrame];
    self.finalView.backgroundColor = COLOR_MAIN_WHITE;
    [self.view addSubview:self.finalView];
    
    self.showImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.showImgView.center = self.finalView.center;
    [self.showImgView setMultipleTouchEnabled:YES];
    [self.showImgView setUserInteractionEnabled:YES];
    [self.showImgView setImage:self.originalImage];
    [self.showImgView setUserInteractionEnabled:YES];
    [self.showImgView setMultipleTouchEnabled:YES];
    
    // scale to fit the screen
    CGFloat oriWidth = self.cropFrame.size.width;
    CGFloat oriHeight = self.originalImage.size.height * (oriWidth / self.originalImage.size.width);
    
    if (self.shouldInitiallyAspectFillImage)
    {
        CGFloat scaleWidth = self.view.frame.size.width / oriWidth;
        CGFloat scaleHeight = self.view.frame.size.height / oriHeight;
        
        CGFloat scale = fmax(scaleWidth, scaleHeight);
        
        oriWidth *= scale;
        oriHeight *= scale;
    }
    
    CGFloat oriX = self.cropFrame.origin.x + (self.cropFrame.size.width - oriWidth) / 2;
    CGFloat oriY = self.cropFrame.origin.y + (self.cropFrame.size.height - oriHeight) / 2;
    self.oldFrame = CGRectMake(oriX, oriY, oriWidth, oriHeight);
    self.latestFrame = self.oldFrame;
    self.showImgView.frame = self.oldFrame;
    
    self.largeFrame = CGRectMake(0, 0, self.limitRatio * self.oldFrame.size.width, self.limitRatio * self.oldFrame.size.height);
//    self.largeFrame = [self.showImgView convertRect:self.largeFrame toView:self.finalView];

    [self addGestureRecognizers];
    [self.view addSubview:self.showImgView];
    
    self.overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlayView.alpha = .67f;
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0.937 alpha:1.000];
    self.overlayView.userInteractionEnabled = NO;
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.overlayView];
    
    self.ratioView = [[UIView alloc] initWithFrame:self.cropFrame];
//    self.ratioView.backgroundColor = COLOR_MAIN_WHITE;
    self.ratioView.layer.borderColor = self.cropRectColor ? self.cropRectColor.CGColor : [UIColor whiteColor].CGColor;
    self.ratioView.layer.borderWidth = 1.0f;
    self.ratioView.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:self.ratioView];
    
    [self overlayClipping];
}

- (void)initControlBtn {
    self.rotateButton = [[UIButton alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height - 68.0f-5, (Screen_width-15)/2, 68)];
    self.rotateButton.backgroundColor = COLOR_MAIN_WHITE;

    [self.rotateButton addTarget:self action:@selector(rotateAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.rotateButton setImage:[UIImage imageNamed:@"rotate"] forState:UIControlStateNormal];
    [self.rotateButton setImage:[UIImage imageNamed:@"rotate_selected"] forState:UIControlStateSelected];
    [self.view addSubview:self.rotateButton];
    
    self.clipButton = [[UIButton alloc] initWithFrame:CGRectMake((Screen_width-15)/2+10, self.view.frame.size.height - 68.0f-5, (Screen_width-15)/2, 68)];
    self.clipButton.backgroundColor = COLOR_MAIN_WHITE;

    [self.clipButton addTarget:self action:@selector(clipAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.clipButton setImage:[UIImage imageNamed:@"clip_all"] forState:UIControlStateNormal];
    [self.clipButton setImage:[UIImage imageNamed:@"clip_all_selected"] forState:UIControlStateSelected];
    [self.view addSubview:self.clipButton];
}

- (void)rotateAction:(id)sender {
//    [self showAllPic];
    self.showImgView.transform = CGAffineTransformIdentity;
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI/2*self.numberRotate);
    [self.showImgView setTransform:transform];
    self.numberRotate++;
//    CGRect frame = self.showImgView.frame;
//    frame.origin.y *= [UIScreen mainScreen].scale;
//    frame.size.width *= [UIScreen mainScreen].scale;
//    frame.size.height *= [UIScreen mainScreen].scale;
    
    self.imageViewOldFrame = self.showImgView.frame;
}

- (void)clipAction:(id)sender {
    
    _isShowAllPic = !_isShowAllPic;
    
    // 全图or截图
    if (_isShowAllPic) {
        [self.clipButton setImage:[UIImage imageNamed:@"clip"] forState:UIControlStateNormal];
        [self.clipButton setImage:[UIImage imageNamed:@"clip_selected"] forState:UIControlStateSelected];
        [self showAllPic];
        
    }else{
        [self.clipButton setImage:[UIImage imageNamed:@"clip_all"] forState:UIControlStateNormal];
        [self.clipButton setImage:[UIImage imageNamed:@"clip_all_selected"] forState:UIControlStateSelected];
        [self showClipPic];
    }
}


- (void)overlayClipping{
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    // Left side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.ratioView.frame.origin.x,
                                        self.overlayView.frame.size.height));
    // Right side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(
                                        self.ratioView.frame.origin.x + self.ratioView.frame.size.width,
                                        0,
                                        self.overlayView.frame.size.width - self.ratioView.frame.origin.x - self.ratioView.frame.size.width,
                                        self.overlayView.frame.size.height));
    // Top side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.overlayView.frame.size.width,
                                        self.ratioView.frame.origin.y));
    // Bottom side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0,
                                        self.ratioView.frame.origin.y + self.ratioView.frame.size.height,
                                        self.overlayView.frame.size.width,
                                        self.overlayView.frame.size.height - self.ratioView.frame.origin.y + self.ratioView.frame.size.height));
    maskLayer.path = path;
    self.overlayView.layer.mask = maskLayer;
    CGPathRelease(path);
}

// register all gestures
- (void) addGestureRecognizers
{
    // add pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

// pinch gesture handler
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    
    if (self.isShowAllPic) {
        return;// 是否可以缩放
    }
    UIView *view = self.showImgView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

// pan gesture handler
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer{
    
    if (self.isShowAllPic) {
        return;
    }
    
    UIView *view = self.showImgView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat absCenterX = self.cropFrame.origin.x + self.cropFrame.size.width / 2;
        CGFloat absCenterY = self.cropFrame.origin.y + self.cropFrame.size.height / 2;
        CGFloat scaleRatio = self.showImgView.frame.size.width / self.cropFrame.size.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (scaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (scaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

- (CGRect)handleScaleOverflow:(CGRect)newFrame {
    // bounce to original frame
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < self.oldFrame.size.width) {
        newFrame = self.oldFrame;
    }
    if (newFrame.size.width > self.largeFrame.size.width) {
        newFrame = self.largeFrame;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}

- (CGRect)handleBorderOverflow:(CGRect)newFrame {
    // horizontally
    if (newFrame.origin.x > self.cropFrame.origin.x) newFrame.origin.x = self.cropFrame.origin.x;
    if (CGRectGetMaxX(newFrame) < self.cropFrame.size.width) newFrame.origin.x = self.cropFrame.size.width - newFrame.size.width;
    // vertically
    if (newFrame.origin.y > self.cropFrame.origin.y) newFrame.origin.y = self.cropFrame.origin.y;
    if (CGRectGetMaxY(newFrame) < self.cropFrame.origin.y + self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + self.cropFrame.size.height - newFrame.size.height;
    }
    // adapt horizontally rectangle
    if (self.showImgView.frame.size.width > self.showImgView.frame.size.height && newFrame.size.height <= self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + (self.cropFrame.size.height - newFrame.size.height) / 2;
    }
    return newFrame;
}

-(UIImage *)getSubImage{
    CGRect squareFrame = self.cropFrame;
    CGFloat scaleRatio = self.latestFrame.size.width / self.originalImage.size.width;
    CGFloat x = (squareFrame.origin.x - self.latestFrame.origin.x) / scaleRatio;
    CGFloat y = (squareFrame.origin.y - self.latestFrame.origin.y) / scaleRatio;
    CGFloat w = squareFrame.size.width / scaleRatio;
    CGFloat h = squareFrame.size.height / scaleRatio;
    if (self.latestFrame.size.width < self.cropFrame.size.width) {
        CGFloat newW = self.originalImage.size.width;
        CGFloat newH = newW * (self.cropFrame.size.height / self.cropFrame.size.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (self.latestFrame.size.height < self.cropFrame.size.height) {
        CGFloat newH = self.originalImage.size.height;
        CGFloat newW = newH * (self.cropFrame.size.width / self.cropFrame.size.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    CGRect myImageRect = CGRectMake(x, y, w, h);
    CGImageRef imageRef = self.originalImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    return smallImage;
}

- (UIImage *)getSubImageByAlvin{
    
//    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
//    UIGraphicsBeginImageContext(self.view.bounds.size);
//    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImageWriteToSavedPhotosAlbum(image, self,@selector(image:didFinishSavingWithError:contextInfo:) , nil);
//    return image;
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *parentImage=UIGraphicsGetImageFromCurrentImageContext();
    parentImage = [self.view imageByRenderingView];
    CGImageRef imageRef = parentImage.CGImage;
    //-------------> myInmageRect想要截取的区域
    // 解决不清晰的问题，应该缩放了
    CGRect frame = self.cropFrame;
    frame.origin.y *= [UIScreen mainScreen].scale;
    frame.size.width *= [UIScreen mainScreen].scale;
    frame.size.height *= [UIScreen mainScreen].scale;
    
    CGRect myImageRect=frame;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    
    //获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    //转换img
//    UIImage* image = [UIImage imageWithCGImage:subImageRef croppedImageRef:];
    UIImage *image = [UIImage imageWithCGImage:subImageRef scale:[UIScreen mainScreen].scale orientation:parentImage.imageOrientation];
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fixOrientation:(UIImage *)srcImg {
    if (srcImg.imageOrientation == UIImageOrientationUp) return srcImg;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (srcImg.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (srcImg.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, srcImg.size.width, srcImg.size.height,
                                             CGImageGetBitsPerComponent(srcImg.CGImage), 0,
                                             CGImageGetColorSpace(srcImg.CGImage),
                                             CGImageGetBitmapInfo(srcImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (srcImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.height,srcImg.size.width), srcImg.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.width,srcImg.size.height), srcImg.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
