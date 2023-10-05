#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <algorithm>
#import <ranges>
#import <cstring>

namespace AS_UIImageViewStorage {
    namespace setImage {
        void (*original)(id, SEL, UIImage *);
        void custom(id self, SEL _cmd, UIImage *image) {
            original(self, _cmd, image);

            //

            unsigned int ivarsCount;
            Ivar *ivars = class_copyIvarList([self class], &ivarsCount);
            
            auto ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
                auto name = ivar_getName(ivar);
                return !std::strcmp(name, "_imageView");
            });
            
            uintptr_t base = reinterpret_cast<uintptr_t>(self);
            ptrdiff_t offset = ivar_getOffset(*ivar);
            delete ivars;
        
            auto location = reinterpret_cast<void *>(base + offset);
            auto imageView = *static_cast<UIImageView **>(location);

            if (image.symbolImage) {
                NSSymbolBounceEffect *symbolEffect = [[NSSymbolBounceEffect bounceUpEffect] effectWithByLayer];
                NSSymbolEffectOptions *options = [NSSymbolEffectOptions optionsWithRepeating];

                [imageView addSymbolEffect:symbolEffect options:options animated:YES];
            } else {
                [imageView removeAllSymbolEffects];
            }
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    MSHookMessageEx(
        NSClassFromString(@"_UIImageViewStorage"),
        NSSelectorFromString(@"setImage:"),
        reinterpret_cast<IMP>(&AS_UIImageViewStorage::setImage::custom),
        reinterpret_cast<IMP *>(&AS_UIImageViewStorage::setImage::original)
    );

    [pool release];
}
