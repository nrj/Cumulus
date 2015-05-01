/**
 Original Code From, Md. Mahmud Ahsan, http://thinkdiff.net/mixed/base-conversion-handle-upto-36-bases/, 2008.02.28
 Adapted Objective-C, Furkan Mustafa, 2013.05.28
 Description: Alpha Numeric Base Conversion, Handles upto base 36
 */

#import <Foundation/Foundation.h>

static inline NSString* reverseString(NSString* original) {
    const char* chars = [original cStringUsingEncoding:NSASCIIStringEncoding];
    int length = (int)strlen(chars);
    char* new = (char*)malloc(length+1);
    for (int i = 0; i < length; i++)
        new[i] = chars[length - i - 1];
    new[length] = '\0';
    NSString* reverseString = [NSString stringWithCString:new encoding:NSASCIIStringEncoding];
    free(new);
    return reverseString;
}

static inline int otherToDec(NSString *original, int base) {
    const char* str = [original.uppercaseString cStringUsingEncoding:NSASCIIStringEncoding];
    int len = (int)strlen(str);
    int power = len - 1;
    long long i, number, j;
    
    number = 0;
    for (i = 0; i < len; ++i) {
        if (str[i] >= 'A' && str[i] <= 'Z')
            j = str[i] - 65 + 10;
        else
            j = str[i] - 48;
        number += j * pow(base, power);
        power--;
    }
    return (int)number;
}

static inline NSString* decToOther(int number, int base) {
    NSMutableString* final = NSMutableString.string;
    int temp, j;
    
    j = -1;
    do {
        temp = number % base;
        if (temp < 10)
            [final appendFormat:@"%c", 48 + temp];
        else
            [final appendFormat:@"%c", 65 + temp - 10];
        number = number / base;
    } while (number != 0);
    
    return reverseString(final);
}