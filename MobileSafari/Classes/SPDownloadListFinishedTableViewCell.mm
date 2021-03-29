// Copyright (c) 2017-2021 Lars Fröder

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

#import "SPDownloadListFinishedTableViewCell.h"
#import "Extensions.h"

#import "SPDownloadListTableViewController.h"
#import "SPDownloadNavigationController.h"
#import "SPDownload.h"
#import "SPFileManager.h"
#import "../Util.h"
#import "../SafariPlus.h"

#import "SPCellButtonsView.h"
#import "SPCellIconLabelView.h"

@implementation SPDownloadListFinishedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	[self setUpContent];
	[self setUpConstraints];

	return self;
}

- (void)applyDownload:(SPDownload*)download
{
	_download = download;

	[self updateFilesizeForDownload:_download];

	_iconLabelView.label.text = download.filename;
	_iconLabelView.iconView.image = [fileManager iconForDownload:download];
	if(_download.wasCancelled)
	{
		_iconLabelView.label.textColor = [UIColor redColor];
	}
	else
	{
		if([UIColor respondsToSelector:@selector(labelColor)])
		{
			_iconLabelView.label.textColor = [UIColor labelColor];
		}
		else
		{
			_iconLabelView.label.textColor = [UIColor blackColor];
		}
	}

	_targetLabel.text = _download.targetURL.path;

	[self updateButtons];
}

- (void)setUpContent
{
	//Enable separators between imageViews
	[self setSeparatorInset:UIEdgeInsetsZero];

	//Make cell unselectable
	self.selectionStyle = UITableViewCellSelectionStyleNone;

	//Create size label for accessoryView
	_sizeLabel = [[UILabel alloc] init];

	_sizeLabel.textColor = [UIColor lightGrayColor];
	_sizeLabel.adjustsFontSizeToFitWidth = YES;
	_sizeLabel.textAlignment = NSTextAlignmentCenter;
	_sizeLabel.frame = CGRectMake(0,0, 45, 15);
	_sizeLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	self.accessoryView = _sizeLabel;

	//Init custom views
	_iconLabelView = [[SPCellIconLabelView alloc] init];
	_iconLabelView.translatesAutoresizingMaskIntoConstraints = NO;

	_buttonsView = [[SPCellButtonsView alloc] init];
	_buttonsView.translatesAutoresizingMaskIntoConstraints = NO;

	_targetLabel = [[UILabel alloc] init];
	_targetLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;

	[self.contentView addSubview:_iconLabelView];
	[self.contentView addSubview:_buttonsView];
	[self.contentView addSubview:_targetLabel];

	//Set up buttons
	[_buttonsView.topButton addTarget:self action:@selector(restartButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"RestartButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

	[_buttonsView.bottomButton addTarget:self action:@selector(locateButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.bottomButton setImage:[[UIImage imageNamed:@"LocateButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

- (void)setUpConstraints
{
	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_buttonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:25],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_buttonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		//Vertical
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_iconLabelView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:18],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	]];
}

- (void)updateButtons
{
	BOOL fileExists = [fileManager fileExistsAtURL:[_download.targetURL URLByAppendingPathComponent:_download.filename] error:nil];

	_buttonsView.displaysBottomButton = (fileExists && !_download.wasCancelled);
}

- (void)updateFilesizeForDownload:(SPDownload*)download
{
	if(download.filesize <= 0)
	{
		if(download.isHLSDownload && download.expectedDuration > 0) //Fall back to expected duration if possible
		{
			NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
			formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
			formatter.includesApproximationPhrase = NO;
			formatter.includesTimeRemainingPhrase = NO;
			formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
			formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;

			_sizeLabel.text = [formatter stringFromTimeInterval:download.expectedDuration];
		}
		else
		{
			_sizeLabel.text = @"?";
		}
	}
	else
	{
		_sizeLabel.text = [NSByteCountFormatter stringFromByteCount:download.filesize countStyle:NSByteCountFormatterCountStyleFile];
	}
}

- (void)restartButtonPressed
{
	[self.tableViewController restartDownload:_download forCell:self];
}

- (void)locateButtonPressed
{
	[(SPDownloadNavigationController*)self.tableViewController.navigationController showFileInBrowser:[_download.targetURL URLByAppendingPathComponent:_download.filename]];
}

@end
