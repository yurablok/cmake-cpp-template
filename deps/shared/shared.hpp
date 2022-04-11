#pragma once

#ifdef __cplusplus
#   define EXTERN_C extern "C"
#else
#   define EXTERN_C
#endif
#if defined(_MSC_VER)
#   ifndef EXPORT
#       define EXPORT(ReturnType) EXTERN_C __declspec(dllexport) ReturnType
#   endif
#   ifndef IMPORT
#       define IMPORT(ReturnType) EXTERN_C __declspec(dllimport) ReturnType
#   endif
#elif defined(__GNUC__)
#   ifndef EXPORT
#       define EXPORT(ReturnType) EXTERN_C __attribute__((visibility("default"))) ReturnType
#   endif
#   ifndef IMPORT
#       define IMPORT(ReturnType) EXTERN_C ReturnType
#   endif
#else
#   ifndef EXPORT
#       define EXPORT(ReturnType) ReturnType
#   endif
#   ifndef IMPORT
#       define IMPORT(ReturnType) ReturnType
#   endif
#   pragma warning Unknown dynamic link import/export semantics.
#endif

EXPORT(void) shared();
