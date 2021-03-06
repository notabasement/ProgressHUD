//
// Copyright (c) 2014 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ProgressHUD.h"


@interface ProgressHUD ()

@property (nonatomic) BOOL interaction;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIToolbar *hud;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIImageView *image;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic) UIBarStyle style;
@property (nonatomic, strong) UIFont *statusFont;
@property (nonatomic, strong) UIColor *statusColor;
@property (nonatomic, strong) UIColor *spinnerColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *windowColor;
@property (nonatomic, strong) UIImage *imageSuccess;
@property (nonatomic, strong) UIImage *imageError;

@property (nonatomic, copy) void(^customPositionBlock)(UIView *hud, CGRect windowBounds, CGFloat keyboardHeight);

@end


@implementation ProgressHUD

@synthesize interaction, window, background, hud, spinner, image, label;
@synthesize style, statusFont, statusColor, spinnerColor, backgroundColor, windowColor, imageSuccess, imageError;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (ProgressHUD *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once = 0;
	static ProgressHUD *progressHUD;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ progressHUD = [[ProgressHUD alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return progressHUD;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)dismiss
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[[self shared] hudHide];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)show:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = YES;
	[[self shared] hudMake:status image:nil spin:YES hide:NO];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)show:(NSString *)status Interaction:(BOOL)Interaction
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = Interaction;
	[[self shared] hudMake:status image:nil spin:YES hide:NO];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)show:(NSString *)status Interaction:(BOOL)Interaction spin:(BOOL)spin hide:(BOOL)hide
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self shared].interaction = Interaction;
    [[self shared] hudMake:status image:nil spin:spin hide:hide];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)show:(NSString *)status Interaction:(BOOL)Interaction spin:(BOOL)spin hide:(BOOL)hide customPositionBlock:(void(^)(UIView *hud, CGRect windowBounds, CGFloat keyboardHeight))customPositionBlock
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self shared].interaction = Interaction;
    [[self shared] hudMake:status image:nil spin:spin hide:hide customPositionBlock:customPositionBlock];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showSuccess:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = YES;
    [[self shared] hudMake:status image:[self shared].imageSuccess?[self shared].imageSuccess:HUD_IMAGE_SUCCESS spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showSuccess:(NSString *)status Interaction:(BOOL)Interaction
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = Interaction;
	[[self shared] hudMake:status image:[self shared].imageSuccess?[self shared].imageSuccess:HUD_IMAGE_SUCCESS spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showError:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = YES;
	[[self shared] hudMake:status image:[self shared].imageError?[self shared].imageError:HUD_IMAGE_ERROR spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showError:(NSString *)status Interaction:(BOOL)Interaction
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].interaction = Interaction;
	[[self shared] hudMake:status image:[self shared].imageError?[self shared].imageError:HUD_IMAGE_ERROR spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showImage:(UIImage *)image status:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self shared].interaction = YES;
    [[self shared] hudMake:status image:image spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showImage:(UIImage *)image status:(NSString *)status Interaction:(BOOL)Interaction
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self shared].interaction = Interaction;
    [[self shared] hudMake:status image:image spin:NO hide:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)showImage:(UIImage *)image status:(NSString *)status Interaction:(BOOL)Interaction hide:(BOOL)hide
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self shared].interaction = Interaction;
    [[self shared] hudMake:status image:image spin:NO hide:hide];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([delegate respondsToSelector:@selector(window)])
		window = [delegate performSelector:@selector(window)];
	else window = [[UIApplication sharedApplication] keyWindow];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    self.frame = window.bounds;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	background = nil; hud = nil; spinner = nil; image = nil; label = nil;
    style = HUD_STYLE;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.alpha = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudMake:(NSString *)status image:(UIImage *)img spin:(BOOL)spin hide:(BOOL)hide
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self hudMake:status image:img spin:spin hide:hide customPositionBlock:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudMake:(NSString *)status image:(UIImage *)img spin:(BOOL)spin hide:(BOOL)hide customPositionBlock:(void(^)(UIView *hud, CGRect windowBounds, CGFloat keyboardHeight))customPositionBlock
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self hudCreate];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	label.text = status;
	label.hidden = (status == nil) ? YES : NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	image.image = img;
	image.hidden = (img == nil) ? YES : NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
    self.customPositionBlock = customPositionBlock;
    //---------------------------------------------------------------------------------------------------------------------------------------------
	if (spin) [spinner startAnimating]; else [spinner stopAnimating];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self hudSize];
	[self hudPosition:nil];
	[self hudShow];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (hide) [NSThread detachNewThreadSelector:@selector(timedHide) toTarget:self withObject:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudCreate
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (hud == nil)
	{
		hud = [[UIToolbar alloc] initWithFrame:CGRectZero];
		hud.translucent = YES;
        hud.barStyle = style;
        hud.backgroundColor = backgroundColor ? backgroundColor : HUD_BACKGROUND_COLOR;
		hud.layer.cornerRadius = 10;
		hud.layer.masksToBounds = YES;
        hud.translatesAutoresizingMaskIntoConstraints = YES;
        hud.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self registerNotifications];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (hud.superview == nil)
	{
		if (interaction == NO)
		{
			background = [[UIView alloc] initWithFrame:window.frame];
            background.backgroundColor = windowColor ? windowColor : HUD_WINDOW_COLOR;
            background.translatesAutoresizingMaskIntoConstraints = YES;
            background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[window addSubview:background];
			[background addSubview:hud];
		}
		else [window addSubview:hud];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (spinner == nil)
	{
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.color = spinnerColor ? spinnerColor : HUD_SPINNER_COLOR;
		spinner.hidesWhenStopped = YES;
	}
	if (spinner.superview == nil) [hud addSubview:spinner];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (image == nil)
	{
		image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
	}
	if (image.superview == nil) [hud addSubview:image];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (label == nil)
	{
		label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = statusFont ? statusFont : HUD_STATUS_FONT;
        label.textColor = statusColor ? statusColor : HUD_STATUS_COLOR;
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		label.numberOfLines = 0;
	}
	if (label.superview == nil) [hud addSubview:label];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)registerNotifications
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudPosition:)
												 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudPosition:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudPosition:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudPosition:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudPosition:) name:UIKeyboardDidShowNotification object:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudDestroy
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[label removeFromSuperview];		label = nil;
	[image removeFromSuperview];		image = nil;
	[spinner removeFromSuperview];		spinner = nil;
	[hud removeFromSuperview];			hud = nil;
	[background removeFromSuperview];	background = nil;
    self.customPositionBlock = nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudSize
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    const UIEdgeInsets imageInsets = UIEdgeInsetsMake(24.0, 24.0, 24.0, 24.0);
    const CGSize imageSize = image.image && !image.hidden ? image.image.size : CGSizeMake(25.0, 25.0);
    const UIEdgeInsets labelInsets = UIEdgeInsetsMake(17.0, 12.0, 14.0, 12.0);
    //---------------------------------------------------------------------------------------------------------------------------------------------
    CGRect labelRect = CGRectZero;
    CGFloat hudWidth = MAX(imageInsets.left + imageSize.width + imageInsets.right, 150.0);
    CGFloat hudHeight = MAX(imageInsets.top + imageSize.height + imageInsets.bottom, 150.0);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (label.text != nil)
	{
		NSDictionary *attributes = @{NSFontAttributeName:label.font};
		NSInteger options = NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
		labelRect = [label.text boundingRectWithSize:CGSizeMake(150.0, CGFLOAT_MAX) options:options attributes:attributes context:NULL];
        
        hudWidth = MAX(hudWidth, labelInsets.left + labelRect.size.width + labelInsets.right);
        labelRect.origin.x = round((hudWidth - labelRect.size.width) / 2.0);

        if (image.image || !image.hidden || spinner.isAnimating) { // Image or Spinner visible
            labelRect.origin.y = imageInsets.top + imageSize.height + labelInsets.top;
        } else {
            labelRect.origin.y = labelInsets.top;
        }
        
        hudHeight = MIN(hudHeight, labelRect.origin.y + labelRect.size.height + labelInsets.bottom);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	hud.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CGFloat imagex = hudWidth/2;
	CGFloat imagey = (label.text == nil) ? hudHeight/2 : imageInsets.top + imageSize.height / 2.0;
	image.center = spinner.center = CGPointMake(imagex, imagey);
    image.bounds = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	label.frame = labelRect;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudPosition:(NSNotification *)notification
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	CGFloat heightKeyboard = 0;
	NSTimeInterval duration = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (notification != nil)
	{
		NSDictionary *info = [notification userInfo];
		CGRect keyboard = [[info valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		duration = [[info valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		if ((notification.name == UIKeyboardWillShowNotification) || (notification.name == UIKeyboardDidShowNotification))
		{
			heightKeyboard = keyboard.size.height;
		}
	}
	else heightKeyboard = [self keyboardHeight];
	//---------------------------------------------------------------------------------------------------------------------------------------------
    CGRect screen = window.bounds; // Using window.bounds instead of mainScreen.bounds to adopt Split View
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if (self.customPositionBlock) {
            self.customPositionBlock(hud, screen, heightKeyboard);
        } else {
            hud.center = CGPointMake(screen.size.width/2, (screen.size.height-heightKeyboard)/2);
        }
	} completion:nil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (background != nil) background.frame = window.frame;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)keyboardHeight
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	for (UIWindow *testWindow in [[UIApplication sharedApplication] windows])
	{
		if ([[testWindow class] isEqual:[UIWindow class]] == NO)
		{
			for (UIView *possibleKeyboard in [testWindow subviews])
			{
				if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"])
				{
					return possibleKeyboard.bounds.size.height;
				}
				else if ([[possibleKeyboard description] hasPrefix:@"<UIInputSetContainerView"])
				{
					for (UIView *hostKeyboard in [possibleKeyboard subviews])
					{
						if ([[hostKeyboard description] hasPrefix:@"<UIInputSetHost"])
						{
							return hostKeyboard.frame.size.height;
						}
					}
				}
			}
		}
	}
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudShow
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    void (^block)() = ^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hudHide) object:nil];
        
        if (self.alpha == 0.0) {
            
            self.alpha = 1.0;
            
            hud.alpha = 0;
            hud.transform = CGAffineTransformScale(hud.transform, 1.4, 1.4);
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
                
                hud.transform = CGAffineTransformIdentity;
                hud.alpha = 1;
                
            } completion:nil];
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)hudHide
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    void (^block)() = ^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hudHide) object:nil];
        
        if (self.alpha == 1.0) {
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
                
                hud.transform = CGAffineTransformScale(hud.transform, 0.7, 0.7);
                hud.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                if (finished) {
                    [self hudDestroy];
                    self.alpha = 0.0;
                }
            }];
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)timedHide
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    void (^block)() = ^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hudHide) object:nil];
        
        double length = label.text.length;
        NSTimeInterval sleep = length * 0.04 + 0.5;
        [self performSelector:@selector(hudHide) withObject:nil afterDelay:sleep inModes:@[NSRunLoopCommonModes]];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setStyle:(UIBarStyle)newStyle
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    style = newStyle;
    
    if (hud)
    {
        hud.barStyle = newStyle;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setStyle:(UIBarStyle)style
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setStyle:style];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setStatusFont:(UIFont *)newStatusFont
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    statusFont = newStatusFont;
    
    if (label)
    {
        label.font = newStatusFont;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setStatusFont:(UIFont *)newStatusFont
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setStatusFont:newStatusFont];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setStatusColor:(UIColor *)newStatusColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    statusColor = newStatusColor;
    
    if (label)
    {
        label.textColor = newStatusColor;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setStatusColor:(UIColor *)newStatusColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setStatusColor:newStatusColor];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setSpinnerColor:(UIColor *)newSpinnerColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    spinnerColor = newSpinnerColor;
    
    if (spinner)
    {
        spinner.color = newSpinnerColor;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setSpinnerColor:(UIColor *)newSpinnerColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setSpinnerColor:newSpinnerColor];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setBackgroundColor:(UIColor *)newBackgroundColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    backgroundColor = newBackgroundColor;
    
    if (hud)
    {
        hud.backgroundColor = newBackgroundColor;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setBackgroundColor:(UIColor *)newBackgroundColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setBackgroundColor:newBackgroundColor];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setWindowColor:(UIColor *)newWindowColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    windowColor = newWindowColor;
    
    if (background)
    {
        background.backgroundColor = newWindowColor;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setWindowColor:(UIColor *)newWindowColor
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setWindowColor:newWindowColor];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setImageSuccess:(UIImage *)newImageSuccess
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    imageSuccess = newImageSuccess;
    
    if (image)
    {
        image.image = newImageSuccess;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setImageSuccess:(UIImage *)newImageSuccess
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setImageSuccess:newImageSuccess];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setImageError:(UIImage *)newImageError
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    imageError = newImageError;
    
    if (image)
    {
        image.image = newImageError;
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)setImageError:(UIImage *)newImageError
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [[self shared] setImageError:newImageError];
}

@end
