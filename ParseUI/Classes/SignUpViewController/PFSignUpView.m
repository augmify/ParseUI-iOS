/*
 *  Copyright (c) 2014, Facebook, Inc. All rights reserved.
 *
 *  You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 *  copy, modify, and distribute this software in source code or binary form for use
 *  in connection with the web services and APIs provided by Facebook.
 *
 *  As with any software that integrates with the Facebook platform, your use of
 *  this software is subject to the Facebook Developer Principles and Policies
 *  [http://developers.facebook.com/policy/]. This copyright notice shall be
 *  included in all copies or substantial portions of the software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "PFSignUpView.h"

#import "PFColor.h"
#import "PFDismissButton.h"
#import "PFImage.h"
#import "PFPrimaryButton.h"
#import "PFRect.h"
#import "PFTextButton.h"
#import "PFTextField.h"

static NSString *const PFSignUpViewDefaultLogoImageName = @"parse_logo.png";

@implementation PFSignUpView

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithFields:(PFSignUpFields)otherFields {
    self = [super init];
    if (!self) return nil;

    _fields = otherFields;

    self.opaque = YES;
    self.backgroundColor = [PFColor commonBackgroundColor];

    _logo = [[UIImageView alloc] initWithImage:[PFImage imageNamed:PFSignUpViewDefaultLogoImageName]];
    _logo.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_logo];

    if (_fields & PFSignUpFieldsDismissButton) {
        _dismissButton = [[PFDismissButton alloc] initWithFrame:CGRectZero];
        [self addSubview:_dismissButton];
    }

    _usernameField = [[PFTextField alloc] initWithFrame:CGRectZero
                                         separatorStyle:(PFTextFieldSeparatorStyleTop |
                                                         PFTextFieldSeparatorStyleBottom)];
    _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameField.returnKeyType = UIReturnKeyNext;
    [self addSubview:_usernameField];
    [self _updateUsernameFieldPlaceholder];

    _passwordField = [[PFTextField alloc] initWithFrame:CGRectZero
                                         separatorStyle:PFTextFieldSeparatorStyleBottom];
    _passwordField.placeholder = NSLocalizedString(@"Password", @"Password");
    _passwordField.secureTextEntry = YES;
    _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if (!(_fields & PFSignUpFieldsEmail) && !(_fields & PFSignUpFieldsAdditional)) {
        _passwordField.returnKeyType = UIReturnKeyDone;
    } else {
        _passwordField.returnKeyType = UIReturnKeyNext;
    }
    [self addSubview:_passwordField];

    if (_fields & PFSignUpFieldsEmail) {
        _emailField = [[PFTextField alloc] initWithFrame:CGRectZero
                                          separatorStyle:PFTextFieldSeparatorStyleBottom];
        _emailField.autocorrectionType = UITextAutocorrectionTypeNo;
        _emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _emailField.keyboardType = UIKeyboardTypeEmailAddress;
        _emailField.placeholder = NSLocalizedString(@"Email", @"Email");
        if (!(_fields & PFSignUpFieldsAdditional)) {
            _emailField.returnKeyType = UIReturnKeyDone;
        } else {
            _emailField.returnKeyType = UIReturnKeyNext;
        }
        [self addSubview:_emailField];
    }

    if (_fields & PFSignUpFieldsAdditional) {
        _additionalField = [[PFTextField alloc] initWithFrame:CGRectZero
                                               separatorStyle:PFTextFieldSeparatorStyleBottom];
        _additionalField.autocorrectionType = UITextAutocorrectionTypeNo;
        _additionalField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _additionalField.placeholder = NSLocalizedString(@"Additional", @"Additional");
        _additionalField.returnKeyType = UIReturnKeyDone;
        [self addSubview:_additionalField];
    }

    if (_fields & PFSignUpFieldsSignUpButton) {
        _signUpButton = [[PFPrimaryButton alloc] initWithBackgroundImageColor:[PFColor signupButtonBackgroundColor]];
        [_signUpButton setTitle:NSLocalizedString(@"Sign Up", @"Sign Up") forState:UIControlStateNormal];
        [self addSubview:_signUpButton];
    }

    return self;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
    [super layoutSubviews];

    self.contentSize = self.bounds.size;
    CGRect bounds = self.bounds;

    if (_dismissButton) {
        CGPoint origin = CGPointMake(16.0f, 16.0f);

        // In iOS 7+, if the view controller that contains this view
        // is presented modally, it's edges extend under the status bar.
        // This lets us move down the dismiss button a bit so that it's not covered by the status bar.
        if ([self.presentingViewController respondsToSelector:@selector(topLayoutGuide)]) {
            origin.y += self.presentingViewController.topLayoutGuide.length;
        }

        CGRect frame = PFRectMakeWithOriginSize(origin, [_dismissButton sizeThatFits:bounds.size]);
        _dismissButton.frame = frame;
    }

    const CGRect contentRect = PFRectMakeWithSizeCenteredInRect([self _contentSizeThatFits:bounds.size],
                                                                PFRectMakeWithSize(bounds.size));
    const CGSize contentSize = contentRect.size;
    const CGSize contentSizeScale = [self _contentSizeScaleForContentSize:bounds.size];

    CGFloat currentY = CGRectGetMinY(contentRect);
    if (_logo) {
        CGFloat logoTopInset = floorf(48.0f * contentSizeScale.height);
        CGFloat logoBottomInset = floorf(36.0f * contentSizeScale.height);

        CGFloat logoAvailableHeight = floorf(68.0f * contentSizeScale.height);

        CGSize logoSize = [_logo sizeThatFits:CGSizeMake(contentSize.width, logoAvailableHeight)];
        logoSize.width = MIN(contentSize.width, logoSize.width);
        logoSize.height = MIN(logoAvailableHeight, logoSize.height);

        CGRect frame = PFRectMakeWithSizeCenteredInRect(logoSize, contentRect);
        frame.origin.y = CGRectGetMinY(contentRect) + logoTopInset;
        _logo.frame = CGRectIntegral(frame);

        currentY = floorf(CGRectGetMaxY(frame) + logoBottomInset);
    }

    if (_usernameField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_usernameField sizeThatFits:contentSize], contentRect);
        frame.origin.y = currentY;
        _usernameField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_passwordField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_passwordField sizeThatFits:contentSize], contentRect);
        frame.origin.y = currentY;
        _passwordField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_emailField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_emailField sizeThatFits:contentSize], contentRect);
        frame.origin.y = currentY;
        _emailField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_additionalField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_additionalField sizeThatFits:contentSize], contentRect);
        frame.origin.y = currentY;
        _additionalField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_signUpButton) {
        CGFloat loginButtonTopInset = floorf(24.0f * contentSizeScale.height);

        CGRect frame = PFRectMakeWithSizeCenteredInRect([_signUpButton sizeThatFits:contentSize], contentRect);;
        frame.origin.y = currentY + loginButtonTopInset;
        _signUpButton.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }
}

- (CGSize)_contentSizeThatFits:(CGSize)boundingSize {
    CGSize maxContentSize = [self _maxContentSize];
    CGSize contentSizeScale = [self _contentSizeScaleForContentSize:boundingSize];

    CGSize size = PFSizeMin(maxContentSize, boundingSize);
    size.height = 0.0f;
    if (_logo) {
        CGFloat logoTopInset = floorf(36.0f * contentSizeScale.height);
        CGFloat logoBottomInset = floorf(36.0f * contentSizeScale.height);

        CGFloat logoAvailableHeight = floorf(68.0f * contentSizeScale.height);

        CGFloat scale = MAX(contentSizeScale.width, contentSizeScale.height);

        CGSize logoSize = [_logo sizeThatFits:CGSizeMake(boundingSize.width, logoAvailableHeight)];
        logoSize.height *= scale;
        logoSize.width *= scale;

        size.height += logoSize.height + logoTopInset + logoBottomInset;
    }
    if (_usernameField) {
        CGSize fieldSize = [_usernameField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_passwordField) {
        CGSize fieldSize = [_passwordField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_emailField) {
        CGSize fieldSize = [_emailField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_additionalField) {
        CGSize fieldSize = [_additionalField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_signUpButton) {
        CGFloat buttonTopInset = floorf(24.0f * contentSizeScale.height);

        CGSize buttonSize = [_signUpButton sizeThatFits:boundingSize];

        size.height += buttonSize.height + buttonTopInset;
    }

    size.width = floorf(size.width);
    size.height = floorf(size.height);

    return size;
}

- (CGSize)_maxContentSize {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
            CGSizeMake(420.0f, 500.0f) :
            CGSizeMake(500.0f, 800.0f));
}

- (CGSize)_contentSizeScaleForContentSize:(CGSize)contentSize {
    CGSize maxContentSize = [self _maxContentSize];
    if (maxContentSize.width < contentSize.width &&
        maxContentSize.height < contentSize.height) {
        return CGSizeMake(1.0f, 1.0f);
    }

    CGSize contentSizeScale = CGSizeMake(contentSize.width / maxContentSize.width,
                                         contentSize.height / maxContentSize.height);
    return contentSizeScale;
}

#pragma mark -
#pragma mark PFSignUpView

- (void)setLogo:(UIView *)logo {
    if (self.logo != logo) {
        [_logo removeFromSuperview];
        _logo = logo;
        [self addSubview:_logo];

        [self setNeedsLayout];
    }
}

- (void)setEmailAsUsername:(BOOL)otherEmailAsUsername {
    if (_emailAsUsername != otherEmailAsUsername) {
        _emailAsUsername = otherEmailAsUsername;

        if (_emailAsUsername) {
            if (_emailField.superview) {
                [_emailField removeFromSuperview];
            }
        } else {
            if (_emailField.superview == nil) {
                [self addSubview:_emailField];
            }
            [self setNeedsLayout];
        }
        [self _updateUsernameFieldPlaceholder];
    }
}

#pragma mark -
#pragma mark Private

- (void)_updateUsernameFieldPlaceholder {
    NSString *placeholder;
    if (!_emailAsUsername) {
        placeholder = NSLocalizedString(@"Username", @"Username");
    } else {
        placeholder = NSLocalizedString(@"Email", @"Email");
    }

    _usernameField.placeholder = placeholder;
}

@end
