//
//  XGSMarkdownInsertionController.m
//  MarkdownEditor
//
//  Created by Julien Grimault on 20/10/13.
//  Copyright (c) 2013 XiaoGouSoftware. All rights reserved.
//

#import "XGSMarkdownInsertionController.h"
#import "XGSMarkdownTag.h"

@interface XGSMarkdownInsertionController()
@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation XGSMarkdownInsertionController

- (id)initWithTextStorage:(NSTextStorage *)textStorage textView:(UITextView *)textView
{
    self = [super init];
    if (self) {
        _textStorage = textStorage;
        _textView = textView;
    }
    return self;
}

#pragma mark - XGSMarkdownInputViewDelegate
- (void)markdownInputViewDidDismiss:(XGSMarkdownInputAccessoryView *)inputView
{
    [self.textView resignFirstResponder];
}

- (void)markdownInputView:(XGSMarkdownInputAccessoryView *)inputView didSelectString:(NSString *)element
{
    NSRange selectedRange = self.textView.selectedRange;
    NSAttributedString *toInsert = [[NSAttributedString alloc] initWithString:element];
    [self.textStorage replaceCharactersInRange:selectedRange withAttributedString:toInsert];
}

- (void)markdownInputView:(XGSMarkdownInputAccessoryView *)inputView didSelectMarkdownElement:(XGSMarkdownTag *)element
{
    [self insertMarkdownTag:element];
}

- (void)insertMarkdownTag:(XGSMarkdownTag *)tag
{
    NSRange selectedRange = self.textView.selectedRange;
    NSAttributedString *insertBefore = [[NSAttributedString alloc] initWithString:tag.partialPatterns[0]];
    NSAttributedString *insertAfter = [self endOfPattern:tag];
    
    // the order in which we insert the 2 segments of the pattern is important - we must insert right part of the pattern first
    // in order to not shift the letters
    [self insertEndOfPattern:insertAfter];
    
    [self.textStorage insertAttributedString:insertBefore
                                     atIndex:selectedRange.location];
    
    if (selectedRange.length > 0)
    {
        self.textView.selectedRange = NSMakeRange(NSMaxRange(selectedRange) + tag.pattern.length, 0);
    }
    else
    {
        self.textView.selectedRange = NSMakeRange(selectedRange.location+ insertBefore.length, 0);
    }

}

    - (NSAttributedString *)endOfPattern:(XGSMarkdownTag *)tag
    {
        NSAttributedString *insertAfter = nil;
        if (tag.partialPatterns.count < 1) return insertAfter;
        
        NSMutableArray *restPartialPatterns = [tag.partialPatterns mutableCopy];
        [restPartialPatterns removeObjectAtIndex:0];
        NSString *restPattern = [restPartialPatterns componentsJoinedByString:@""];
        insertAfter = [[NSAttributedString alloc] initWithString:restPattern];
        
        return insertAfter;
    }

    - (void)insertEndOfPattern:(NSAttributedString *)insertAfter
    {
        if (insertAfter != nil)
        {
            NSUInteger insertionEnd = NSMaxRange(self.textView.selectedRange);
            if (insertionEnd == self.textStorage.string.length)
            {
                [self.textStorage appendAttributedString:insertAfter];
            } else {
                [self.textStorage insertAttributedString:insertAfter
                                                 atIndex:insertionEnd];
            }
        }
    }

@end
