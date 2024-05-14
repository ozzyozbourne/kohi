#pragma once

#include "defines.h"

// Disable assertions by commenting out the below line
#define KASSERTIONS_ENABLED

#ifdef KASSERTIONS_ENABLED
#if _MSC_VER
#include <intrin.h>
#define debugBreak() __debugbreak()
#else
#define debugBreak() __builtin_trap()
#endif // _MSC_VER

KAPI void report_assertion_failure(const char* expression, const char* message, const char* file, i32 line);

#define KASSERT(expr)                                                \
    {                                                                \
        if(expr){                                                    \
                                                                     \
        }else{                                                       \
            report_assertion_failure(#expr, "", __FILE__, __LINE__); \
            debugBreak();                                            \
        }                                                            \
                                                                     \
}                                                                    \

#define KASSERT_MSG(expr)                                                 \
    {                                                                     \
        if(expr){                                                         \
                                                                          \
        }else{                                                            \
            report_assertion_failure(#expr, message, __FILE__, __LINE__); \
            debugBreak();                                                 \
        }                                                                 \
                                                                          \
}

#ifdef DEBUG
#define KASSERT_DEBUG(expr)                                          \
    {                                                                \
        if(expr){                                                    \
                                                                     \
        }else{                                                       \
            report_assertion_failure(#expr, "", __FILE__, __LINE__); \
            debugBreak();                                            \
        }                                                            \
                                                                     \
}
#else 
#define KASSERT_DEBUG(expr)             // Does nothing at all!
#endif // DEBUG
#else 
#define KASSERT(expr)                   // Does nothing at all!
#define KASSERT_MSG(expr, message)      // Does nothing at all!
#define KASSERT_DEBUG(expr)             // Does nothing at all!
#endif // !KASSERTIONS_ENABLED  
