//
//  XLFormTextViewCell.m
//  XLForm ( https://github.com/xmartlabs/XLForm )
//
//  Copyright (c) 2014 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "XLFormRowDescriptor.h"
#import "UIView+XLFormAdditions.h"
#import "XLFormViewController.h"
#import "XLFormTextView.h"
#import "XLFormTextViewCell.h"

NSString *const kFormTextViewCellPlaceholder = @"placeholder";

@interface XLFormTextViewCell() <UITextViewDelegate>

@end

@implementation XLFormTextViewCell
{
    NSArray * _horizontalConstraints;
	NSArray * _verticalConstraints;
}

@synthesize label = _label;
@synthesize textView = _textView;

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.label && [keyPath isEqualToString:@"text"]){
        if ([[change objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:@(NSKeyValueChangeSetting)]){
            [self needsUpdateConstraints];
        }
    }
}

-(void)dealloc
{
    [self.label removeObserver:self forKeyPath:@"text"];
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self){
		_layoutDirection = XLFormTextViewCellLayoutDirectionHorizontal;
    }

    return self;
}


#pragma mark - Properties

-(UILabel *)label
{
    if (_label) return _label;
    _label = [UILabel autolayoutView];
    [_label setContentHuggingPriority:500 forAxis:UILayoutConstraintAxisHorizontal];
    return _label;
}

-(XLFormTextView *)textView
{
    if (_textView) return _textView;
    _textView = [XLFormTextView autolayoutView];
    return _textView;
}


#pragma mark - XLFormDescriptorCell

-(void)configure
{
    [super configure];

    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.contentView addSubview:self.label];
    [self.contentView addSubview:self.textView];
    [self.label addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:0];
}

-(void)update
{
    [super update];
    self.textView.delegate = self;
    self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.placeHolderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.text = self.rowDescriptor.value;
    [self.textView setEditable:!self.rowDescriptor.disabled];
    self.textView.textColor  = self.rowDescriptor.disabled ? [UIColor grayColor] : [UIColor blackColor];
    self.label.textColor = self.rowDescriptor.disabled ? [UIColor grayColor] : [UIColor blackColor];
    self.label.text = ((self.rowDescriptor.required && self.rowDescriptor.title && self.rowDescriptor.sectionDescriptor.formDescriptor.addAsteriskToRequiredRowsTitle) ? [NSString stringWithFormat:@"%@*", self.rowDescriptor.title]: self.rowDescriptor.title);

	[self setNeedsUpdateConstraints];
}

+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 140.f;
}

-(BOOL)formDescriptorCellBecomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

-(BOOL)formDescriptorCellResignFirstResponder
{
    return [self.textView resignFirstResponder];
}

#pragma mark - Constraints

-(void)updateConstraints
{
	NSDictionary * views = @{@"label": self.label, @"textView": self.textView};

	if (_verticalConstraints){
		[self.contentView removeConstraints:_verticalConstraints];
	}

	NSMutableArray* verticalConstraints = [NSMutableArray array];

	switch (self.layoutDirection){
		case XLFormTextViewCellLayoutDirectionHorizontal:
			[verticalConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[label]" options:0 metrics:0 views:views]];
			[verticalConstraints addObject:[NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
			[verticalConstraints addObject:[NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
			break;
		case XLFormTextViewCellLayoutDirectionVertical:
			[verticalConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[label]-0-[textView]-0-|" options:0 metrics:nil views:views]];
	}

	_verticalConstraints = verticalConstraints;
	[self.contentView addConstraints:_verticalConstraints];

    if (_horizontalConstraints){
        [self.contentView removeConstraints:_horizontalConstraints];
    }

	BOOL labelEmpty = (!self.label.text || [self.label.text isEqualToString:@""]);
	switch (self.layoutDirection){
		case XLFormTextViewCellLayoutDirectionHorizontal:
			if (labelEmpty){
				_horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[textView]-16-|" options:0 metrics:0 views:views];
			}
			else{
				_horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[label]-[textView]-16-|" options:0 metrics:0 views:views];
			}
			break;
		case XLFormTextViewCellLayoutDirectionVertical:{
			NSArray* labelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[label]-16-|" options:0 metrics:0 views:views];
			NSArray* textViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[textView]-16-|" options:0 metrics:0 views:views];
			_horizontalConstraints = [labelConstraints arrayByAddingObjectsFromArray:textViewConstraints];
			break;
		}
	}

    [self.contentView addConstraints:_horizontalConstraints];
    [super updateConstraints];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidEndEditing:(UITextView *)textView{
    if([self.textView.text length] > 0) {
        self.rowDescriptor.value = self.textView.text;
    } else {
        self.rowDescriptor.value = nil;
    }
    [self.formViewController textViewDidEndEditing:textView];
}

-(void)textViewDidChange:(UITextView *)textView{
    if([self.textView.text length] > 0) {
        self.rowDescriptor.value = self.textView.text;
    } else {
        self.rowDescriptor.value = nil;
    }
}

@end
