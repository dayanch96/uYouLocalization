#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <rootless.h>

static inline NSBundle *uYouLocalizationBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"uYouLocalization" ofType:@"bundle"];
        NSString *rootlessBundlePath = ROOT_PATH_NS("/Library/Application Support/uYouLocalization.bundle");

        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: rootlessBundlePath];
    });

    return bundle;
}

static inline NSString *LOC(NSString *key) {
    return [uYouLocalizationBundle() localizedStringForKey:key value:nil table:nil];
}

// Replace (translate) old text to the new one
%hook UILabel
- (void)setText:(NSString *)text {
    NSString *localizedText = [uYouLocalizationBundle() localizedStringForKey:text value:nil table:nil];

    if (localizedText && ![localizedText isEqualToString:text]) {
        text = localizedText;
        self.adjustsFontSizeToFitWidth = YES;
    }

    // Replace (translate) only a certain part of the text 
    if ([text containsString:@"TOTAL ("]) {
        text = [NSString stringWithFormat:@"%@ %@", LOC(@"TOTAL"), [text substringFromIndex:[text rangeOfString:@"("].location]];
    }

    if ([text containsString:@"DOWNLOADING ("]) {
        text = [NSString stringWithFormat:@"%@ %@", LOC(@"DOWNLOADING"), [text substringFromIndex:[text rangeOfString:@"("].location]];
    }

    if ([text containsString:@"Selected files: ("]) {
        text = [NSString stringWithFormat:@"%@: %@", LOC(@"SelectedFilesCount"), [text substringFromIndex:[text rangeOfString:@"("].location]];
    }

    if ([text containsString:@"Are you sure you want to delete \""]) {
        text = [NSString stringWithFormat:@"%@ %@", LOC(@"DeleteVideo"), [text substringFromIndex:[text rangeOfString:@"\""].location]];
    }

    if ([text containsString:@"Video •"]) {
        text = [NSString stringWithFormat:@"%@ %@", LOC(@"Video"), [text substringFromIndex:[text rangeOfString:@"•"].location]];
    }

    if ([text containsString:@"Importing ("]) {
        text = [text stringByReplacingOccurrencesOfString:@"Importing" withString:LOC(@"Importing")];
    }

    if ([text containsString:@"Error: Conversion failed with code "]) {
        text = [text stringByReplacingOccurrencesOfString:@"Error: Conversion failed with code" withString:LOC(@"ConversionFailedWithCode")];
    }

    if ([text containsString:@"Are you sure you want to delete ("]) {
        NSRange parenthesesRange = [text rangeOfString:@"("];
        NSRange suffixRange = [text rangeOfString:@")" options:NSBackwardsSearch range:NSMakeRange(parenthesesRange.location, text.length - parenthesesRange.location)];
        if (suffixRange.location != NSNotFound) {
            NSString *textInsideParentheses = [text substringWithRange:NSMakeRange(parenthesesRange.location + 1, text.length - parenthesesRange.location - 2)];
            NSString *newPrefix = LOC(@"DeleteFilesCount");
            NSString *newString = [NSString stringWithFormat:@"%@\n%@: %@", newPrefix, LOC(@"SelectedFilesCount"), textInsideParentheses];
            newString = [newString stringByReplacingOccurrencesOfString:@") files" withString:@""];
            newString = [newString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            text = newString;
        }
    }

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *message = [NSString stringWithFormat:@"Your YouTube app version (%@) is not supported by uYou. For optimal performance, please update YouTube to at least version (", appVersion];

    if ([text containsString:message]) {
        NSRange messageRange = [text rangeOfString:message];
        if (messageRange.location != NSNotFound) {
            NSRange versionRange;
            NSRange startRange = NSMakeRange(messageRange.location + messageRange.length, text.length - messageRange.location - messageRange.length);
            NSRange endRange = [text rangeOfString:@")" options:0 range:startRange];
            if (endRange.location != NSNotFound) {
                versionRange = NSMakeRange(startRange.location, endRange.location - startRange.location);
                NSString *supportedVersion = [text substringWithRange:versionRange];
                text = [NSString stringWithFormat:LOC(@"UnsupportedVersionText"), appVersion, supportedVersion];
            }
        }
    }

    %orig(text);
}
%end

%hook YTLabel
- (void)setFontAttributes:(id)attributes text:(NSString *)text {
    if ([text containsString:@"Completed: "]) {
        text = [text stringByReplacingOccurrencesOfString:@"Completed" withString:LOC(@"Completed")];
    }

    %orig(attributes, text);
}
%end

@interface SSBouncyButton : UIButton
@end

// Make non-attributed buttons text centered
%hook SSBouncyButton
- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    NSString *localizedText = [uYouLocalizationBundle() localizedStringForKey:title value:nil table:nil];
    NSArray *centered = @[@"SKIP", @"DISMISS", @"UPDATE NOW", @"DON'T SHOW", @"Cancel", @"Copy all", @"Move all"];

    if ([centered containsObject:title]) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.titleLabel sizeToFit];
    }

    %orig(localizedText, state);
}
%end

// Replace (translate) old text to the new one in Navbars
%hook _UINavigationBarContentView
- (void)setTitle:(NSString *)title {
    NSString *localizedText = [uYouLocalizationBundle() localizedStringForKey:title value:nil table:nil];

    if (localizedText && ![localizedText isEqualToString:title]) {
        title = localizedText;
    }

    %orig(title);
}
%end

// Continue button (mostly for notched devices)
%hook uYouWelcome
- (void)setButtonTitle:(id)arg1 {
    %orig(arg1 = LOC(@"Continue"));
}
%end

// Follow me on twitter
%hook OBPrivacyLinkButton
- (id)initWithCaption:(id)arg1 buttonText:(id)arg2 image:(id)arg3 imageSize:(CGSize)arg4 useLargeIcon:(BOOL)arg5 {
    return %orig(LOC(@"FollowMe"), arg2, arg3, arg4, arg5);
}
%end

// Translate Donation cell
%hook UserButtonCell
- (id)initWithLabel:(id)arg1 account:(id)arg2 imageName:(id)arg3 logo:(id)arg4 roll:(id)arg5 color:(id)arg6 bundlePath:(id)arg7 avatarBackground:(BOOL)arg8 {
    if ([arg2 containsString:@"developments by"]) {
        arg2 = [arg2 stringByReplacingOccurrencesOfString:@"developments by" withString:LOC(@"Developments")];
    }

    return %orig(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}
%end

// Translate update messages from https://miro92.com/repo/check.php?id=com.miro.uyou&v=3.0 (3.0 - tweak version)
%hook uYouCheckUpdate
- (id)initWithTweakName:(id)arg1 tweakID:(id)arg2 version:(id)tweakVersion message:(id)arg4 tintColor:(id)arg5 showAllButtons:(BOOL)arg6 {
    // Up to date
    if ([arg4 containsString:@"which it\'s the latest version."]) {
        arg4 = [NSString stringWithFormat:LOC(@"UpToDate"), tweakVersion];
    }

    // Update available (new msg)
    else if ([arg4 containsString:@"Please update to the latest version for the best experience."]) {
        NSString *startOfMsg = @"Available version v.";
        NSString *endOfMsg = @"\n\nPlease update";
        NSArray *components = [arg4 componentsSeparatedByString:startOfMsg];

        if (components.count > 1) {
            NSString *newVersion = [components[1] componentsSeparatedByString:endOfMsg].firstObject;
            arg4 = [NSString stringWithFormat:LOC(@"NewVersion"), tweakVersion, newVersion];
        }
    }

    // Update available (old msg)
    else if ([arg4 containsString:@"is now available.\nPlease make sure"]) {
        NSRange getNewVerion = [arg4 rangeOfString:@" is now available."];
        NSString *newVersion = [arg4 substringToIndex:getNewVerion.location];
        arg4 = [NSString stringWithFormat:LOC(@"NewVersionOld"), newVersion];
    }

    return %orig(arg1, arg2, tweakVersion, arg4, arg5, arg6);
}
%end

@interface GOODialogActionMDCButton : UIButton
@end

static BOOL shouldResizeIcon = NO;

%hook GOODialogActionMDCButton
// Replace (translate) old text with the new one and extend its frame
- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    NSString *localizedText = [uYouLocalizationBundle() localizedStringForKey:title value:nil table:nil];

    if (![localizedText isEqualToString:title]) {
        CGSize size = [localizedText sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}];
        CGRect frame = self.frame;
        frame.size.width = size.width;
        self.frame = frame;

        shouldResizeIcon = YES;
    }

    else {
        shouldResizeIcon = NO;
    }

    %orig(localizedText, state);
}

// Re-set images with a fixed frame size
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(22, 22)];
    UIImage *newimage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:image];
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        iconImageView.clipsToBounds = YES;
        iconImageView.tintColor = [UIColor labelColor];
        iconImageView.frame = imageView.bounds;

        [imageView addSubview:iconImageView];
        [imageView.layer renderInContext:rendererContext.CGContext];
    }];

    UIImage *resizedImage = shouldResizeIcon ? newimage : image;
    %orig(resizedImage, state);
}
%end

%hook YTSettingsCell
- (void)setTitleDescription:(id)arg1 {
    if ([arg1 isEqualToString:@"Show uYou settings"]) {
        arg1 = LOC(@"uYouSettings");
    }

    %orig(arg1);
}
%end

// Set labelColor to the uYou's Downloads page scrollview (Tabs)
%hook DownloadsPagerVC
- (UIColor *)ytTextColor {
    return [UIColor labelColor];
}
%end

// Set textAlignment to the natural (left for the LTR and right for the RTL) for the quality footer
@interface _UITableViewHeaderFooterViewLabel : UILabel
@end

%hook _UITableViewHeaderFooterViewLabel
- (void)setTextAlignment:(NSTextAlignment)alignment {
    NSString *localizedText = [uYouLocalizationBundle() localizedStringForKey:@"If the selected quality is not available, then uYou will choose a lower quality than the one you selected." value:nil table:nil];

    if ([self.text isEqualToString:localizedText]) {
        alignment = NSTextAlignmentNatural;
    }

    %orig(alignment);
}
%end
