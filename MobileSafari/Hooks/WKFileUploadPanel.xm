// WKFileUploadPanel.xm
// (c) 2019 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPFilePickerNavigationController.h"
#import "../Classes/SPFileManager.h"
#import "../Defines.h"
#import "../Shared.h"

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

%group iOS9Up

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
		 image:[UIImage imageNamed:@"UploadFileButton.png"
			inBundle:SPBundle compatibleWithTraitCollection:nil]
		 order:UIDocumentMenuOrderFirst handler:
		 ^
		{
			[self _showFilePicker];
		}];
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
		return;
	}

	[fileManager resetHardLinks];

	NSMutableArray* hardLinkedURLs = [NSMutableArray new];

	for(NSURL* URL in URLs)
	{
		[hardLinkedURLs addObject:[fileManager accessibleHardLinkForFileAtURL:URL forced:NO]];
	}

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

	%init();
}
