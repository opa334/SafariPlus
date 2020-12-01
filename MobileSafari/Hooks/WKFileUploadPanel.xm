// Copyright (c) 2017-2020 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPFilePickerNavigationController.h"
#import "../Classes/SPFileManager.h"
#import "../Defines.h"
#import "../Util.h"

%hook WKFileUploadPanel

//Present file picker
%new
- (void)_showFilePicker
{
	SPFilePickerNavigationController* navController = [[%c(SPFilePickerNavigationController) alloc] init];
	navController.filePickerDelegate = self;

	if(IS_PAD)
	{
		[self _presentPopoverWithContentViewController:navController animated:YES];
	}
	else
	{
		[self _presentFullscreenViewController:navController animated:YES];
	}
}

%group iOS14Up

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location
{
	UIContextMenuConfiguration* config = %orig;

	if(preferenceManager.uploadAnyFileOptionEnabled)
	{
		UIContextMenuActionProvider orgProvider = config.actionProvider;

		config.actionProvider = ^UIMenu*(NSArray<UIMenuElement *> *suggestedActions)
		{
			UIMenu* orgMenu = orgProvider(suggestedActions);

			NSMutableArray* children = [orgMenu.children mutableCopy];

			UIAction* localFilesAction = [UIAction actionWithTitle:[localizationManager localizedSPStringForKey:@"LOCAL_FILES"]
				image:[UIImage systemImageNamed:@"doc"]
				identifier:@"com.opa334.safariplus.localfiles"
				handler:^(UIAction* action)
				{
					MSHookIvar<BOOL>(self, "_isPresentingSubMenu") = YES;
					[self _showFilePicker];
				}];

			[children insertObject:localFilesAction atIndex:children.count - 1];

			return [orgMenu menuByReplacingChildren:children];
		};
	}

	return config;
}

%end

%group iOS13Down

//Add button to document menu
- (void)_showDocumentPickerMenu
{
	%orig;
	if(preferenceManager.uploadAnyFileOptionEnabled)
	{
		UIDocumentMenuViewController* documentMenuController =
			MSHookIvar<UIDocumentMenuViewController*>(self, "_documentMenuController");

		[documentMenuController addOptionWithTitle:[localizationManager
							    localizedSPStringForKey:@"LOCAL_FILES"]
		 image:[UIImage imageNamed:@"UploadFileButton"
			inBundle:SPBundle compatibleWithTraitCollection:nil]
		 order:UIDocumentMenuOrderFirst handler:
		 ^
		{
			[self _showFilePicker];
		}];
	}
}

%end

%group iOS9Up

//Dismiss file picker and start upload or cancel
%new
- (void)filePicker:(SPFilePickerNavigationController*)filePicker didSelectFiles:(NSArray*)URLs
{
	[filePicker dismissViewControllerAnimated:YES completion:nil];

	if(!URLs)
	{
		[self _cancel];
		return;
	}

	[fileManager resetHardLinks];

	NSMutableArray* hardLinkedURLs = [NSMutableArray new];

	for(NSURL* URL in URLs)
	{
		[hardLinkedURLs addObject:[fileManager accessibleHardLinkForFileAtURL:URL forced:NO]];
	}

	NSLog(@"hardLinkedURLs = %@", hardLinkedURLs);

	[self _chooseFiles:[hardLinkedURLs copy]
	 displayString:[((NSURL*)hardLinkedURLs.firstObject).lastPathComponent
			stringByRemovingPercentEncoding] iconImage:nil];
}

%end

%group iOS8

- (void)_showPhotoPickerWithSourceType:(int)arg1
{
	if(preferenceManager.uploadAnyFileOptionEnabled)
	{
		//On some sites only the photo picker gets opened, if that's the case, just present the alert nonetheless
		UIAlertController* actionSheetController = MSHookIvar<UIAlertController*>(self, "_actionSheetController");
		if(!actionSheetController)
		{
			[self _showMediaSourceSelectionSheet];
			return;
		}
	}

	%orig;
}

- (void)_showMediaSourceSelectionSheet
{
	%orig;

	if(preferenceManager.uploadAnyFileOptionEnabled)
	{
		UIAlertController* uploadAlert = MSHookIvar<UIAlertController*>(self, "_actionSheetController");

		UIAlertAction* fileAction = [UIAlertAction actionWithTitle:[localizationManager
									    localizedSPStringForKey:@"LOCAL_FILES"]
					     style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
		{
			[self _showFilePicker];
		}];

		//Add 'Local File' option to alert
		[uploadAlert addAction:fileAction];
	}
}

//Dismiss file picker and start upload or cancel
%new
- (void)filePicker:(SPFilePickerNavigationController*)filePicker didSelectFiles:(NSArray*)URLs
{
	[filePicker dismissViewControllerAnimated:YES completion:nil];

	if(!URLs)
	{
		[self _cancel];
	}
	else
	{
		//iOS8 needs the files to be inside sandbox (otherwise WebKit crashes)

		//Mutable array for sandboxed URLs
		NSMutableArray* sandboxedURLs = [NSMutableArray new];

		for(NSURL* URL in URLs)
		{
			//Create URL for tmp location
			NSURL* sandboxedURL = [fileManager accessibleHardLinkForFileAtURL:URL forced:YES];

			//Add URL to array
			[sandboxedURLs addObject:sandboxedURL];
		}

		//Choose files inside sandbox
		[self _chooseFiles:sandboxedURLs
		 displayString:[((NSURL*)sandboxedURLs.firstObject).lastPathComponent
				stringByRemovingPercentEncoding] iconImage:nil];
	}
}

%end

%end

void initWKFileUploadPanel()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up);
	}
	else
	{
		%init(iOS8);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
	{
		%init(iOS14Up);
	}
	else
	{
		%init(iOS13Down);
	}

	%init();
}
