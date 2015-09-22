# [1.0.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v1.0.0)

- Change `WebService` to a final class

# [0.1.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.1.0)

- Various updates for Swift 2 support based on Xcode 7 migration tool
- Enable testability for debug builds only
- Add `percentEncodeURLQueryCharacters` to encode params now that `stringByAddingPercentEscapesUsingEncoding` is deprecated in iOS 9
- Clean up unit tests to fix Xcode 7 warnings
- Audit access control and update tests based on new `@testability` Xcode 7 support 
- Use Swift 2's new `ErrorType` as the error parameter type for error handlers

# [0.0.3](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.0.3)

- Update example web service project to use `throwError()`
- Refactor error handling to utilize `Result` enum

# [0.0.2](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.0.2)

- Added Travis CI support
