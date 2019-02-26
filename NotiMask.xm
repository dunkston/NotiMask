@interface SBApplication
	@property (nonatomic,readonly) NSString * displayName; 
	- (id)icon:(id)arg1 imageWithFormat:(int)arg2;
@end

@interface SBApplicationController
	+ (id)sharedInstance;
	- (SBApplication *)applicationWithBundleIdentifier:(id)arg1;
@end

static BOOL enabled = NO;
static NSString *app = nil;
static NSString *title = nil;
static NSString *message = nil;

static void loadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%s.plist", "com.dunkston.notimask"]];
		app = prefs[@"app"] ? [[NSString alloc] initWithString: prefs[@"app"]] : [[NSString alloc] initWithString: @"com.apple.Preferences"];
		title = prefs[@"title"] ? [[NSString alloc] initWithString: prefs[@"title"]] : [[NSString alloc] init];
		message = prefs[@"message"] ? [[NSString alloc] initWithString: prefs[@"message"]] : [[NSString alloc] init];
	[prefs release];
}

%hook NCNotificationRequest

	- (NSString *)sectionIdentifier {
		NSString *bundleID = %orig;

		NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%s.plist", "com.dunkston.notimask"]];
			enabled = prefs[[NSString stringWithFormat: @"enabled-%@", bundleID]] ? [prefs[[NSString stringWithFormat: @"enabled-%@", bundleID]] boolValue] : NO;
		[prefs release];

		return bundleID;
	}

%end

%hook NCNotificationContent

	- (NSArray *)icons {
		if(enabled) {
			UIImage* icons[] = {[[[%c(SBApplicationController) sharedInstance]
				applicationWithBundleIdentifier: app] icon: nil
				imageWithFormat: 5]};
			return [NSArray arrayWithObjects: icons count: 1];
		}
		else return %orig;
	}

	- (NSString *)header {
		if(enabled) return [[%c(SBApplicationController) sharedInstance]
			applicationWithBundleIdentifier: app].displayName;
		else return %orig;
	}

	- (NSString *)title {
		if(enabled && ![title isEqualToString: @"orig"]) return title;
		else return %orig;
	}

	- (NSString *)message {
		if(enabled && ![message isEqualToString: @"orig"]) return message;
		else return %orig;
	}

%end

%ctor {
	loadPrefs(nil, nil, nil, nil, nil);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.dunkston.notimask.preferencesChanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
}