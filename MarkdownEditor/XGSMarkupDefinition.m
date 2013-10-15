//
//  XGSMarkupDefinition.m
//  TextKitPlayground
//
//  Created by Julien Grimault on 11/10/13.
//  Copyright (c) 2013 XiaoGouSoftware. All rights reserved.
//

#import "XGSMarkupDefinition.h"
#import "OrderedDictionary.h"
#import "XGSMarkdownTag.h"

@interface XGSMarkupDefinition()

// keys are regex for the tags and values are - we use an ordered dictionary because the order in which tag
// processing blocks run is important - a tag recognizing **xxx** must run before a tag recognizing *xxx*
@property (nonatomic, strong) OrderedDictionary *tagProcessingBlocks;

@property (nonatomic, strong) UIFont *italicFont;
@property (nonatomic, strong) UIFont *boldFont;
@end

@implementation XGSMarkupDefinition


+(instancetype)sharedInstance
{
    static XGSMarkupDefinition *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[XGSMarkupDefinition alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self computeFonts];
        [self computeTags];
    }
    return self;
}

- (void)setNormalFont:(UIFont *)normalFont
{
    if (_normalFont == normalFont) return;
    
    _normalFont = normalFont;
    [self computeFonts];
    [self computeTags];
}

- (void)computeFonts
{
    // get the body font descriptor + the size
    UIFontDescriptor *bodyFontDescriptor = [UIFontDescriptor
                                        preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    NSNumber *bodyFontSize = bodyFontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute];
    
    //get the normal font
    _normalFont = [UIFont fontWithDescriptor:bodyFontDescriptor size:[bodyFontSize floatValue]];
    
    // derive the bold font
    UIFontDescriptor *boldFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    _boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0.0];
    
    //derive the italic font
    UIFontDescriptor *italicFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    _italicFont = [UIFont fontWithDescriptor:italicFontDescriptor size:0.0];
}

- (void)computeTags
{
    _markdownTags = @[[XGSMarkdownTag italic], [XGSMarkdownTag bold], [XGSMarkdownTag underlined]];
    _tagStyles = [OrderedDictionary new];
    [_tagStyles insertObject:@{NSFontAttributeName : _italicFont}
                      forKey:_markdownTags[0]
                     atIndex:0];
    [_tagStyles insertObject:@{NSUnderlineStyleAttributeName : @1}
                      forKey:_markdownTags[2]
                     atIndex:1];
    [_tagStyles insertObject:@{NSFontAttributeName : _boldFont}
                      forKey:_markdownTags[1]
                     atIndex:2];

    
    _tagProcessingBlocks = [OrderedDictionary new];
    [_tagProcessingBlocks insertObject:[self tagProcessorForAttribute:@{NSFontAttributeName : _boldFont}]
                                forKey:_markdownTags[1]
                               atIndex:0];
    [_tagProcessingBlocks insertObject:[self tagProcessorForAttribute:@{NSUnderlineStyleAttributeName : @1}]
                      forKey:_markdownTags[2]
                     atIndex:1];
    [_tagProcessingBlocks insertObject:[self tagProcessorForAttribute:@{NSFontAttributeName : _italicFont}]
                                forKey:_markdownTags[0]
                               atIndex:2];
}


#pragma mark - Markdown Parsing

- (TagProcessorBlockType)tagProcessorForAttribute:(NSDictionary *)attributes
{
    return ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
    {
        NSRange textRange = [match rangeAtIndex:1];
        if (textRange.length>0)
        {
            NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
            NSRange r = NSMakeRange(0,textRange.length);
            [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attribute, id value, BOOL *stop) {
                [foundString addAttribute:attribute value:value range:r];
            }];
            return foundString;
        } else {
            return nil;
        }
    };
}

- (NSAttributedString *)parseAttributedString:(NSAttributedString *)input
{
    NSMutableAttributedString *mutAttrString = [input mutableCopy];
    
    [self.tagProcessingBlocks enumerateKeysAndObjectsUsingBlock:^(XGSMarkdownTag *tag, TagProcessorBlockType block, BOOL *stop) {
         [self parsePattern:tag.regex processingBlock:block input:mutAttrString];
     }];
    return [mutAttrString copy];
}

    - (void)parsePattern:(NSString *)pattern processingBlock:(TagProcessorBlockType)block input:(NSMutableAttributedString *)input
    {
        NSRegularExpression* regEx = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSAttributedString* processedString = [input copy];
        
        __block NSUInteger offset = 0;
        NSRange range = NSMakeRange(0, processedString.length);
        [regEx enumerateMatchesInString:processedString.string options:0 range:range
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop2)
         {
             NSAttributedString* repl = block(processedString, result);
             if (repl)
             {
                 NSRange offsetRange = NSMakeRange(result.range.location - offset, result.range.length);
                 [input replaceCharactersInRange:offsetRange withAttributedString:repl];
                 offset += result.range.length - repl.length;
             }
         }];
    }

@end
