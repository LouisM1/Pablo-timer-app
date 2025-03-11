# Errors

## TimerListViewModel HapticManager Errors

```
/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:98:38 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:98:60 Cannot infer contextual base in reference to member 'success'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:105:38 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:105:60 Cannot infer contextual base in reference to member 'success'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:111:34 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:111:56 Cannot infer contextual base in reference to member 'success'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:339:42 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:339:64 Cannot infer contextual base in reference to member 'success'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:346:42 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:346:64 Cannot infer contextual base in reference to member 'success'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:352:38 Value of type 'HapticManager' has no member 'notificationFeedback'

/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:352:60 Cannot infer contextual base in reference to member 'success'
```

## Resolution

These errors are related to incorrect calls to the `HapticManager` class. The `HapticManager` doesn't have a method called `notificationFeedback` that accepts a parameter like `.success`.

Instead, we should use the existing feedback methods in the `HapticManager` class:
- `successFeedback()`
- `errorFeedback()`
- `mediumImpactFeedback()`
- etc.

The fix involves replacing all instances of `HapticManager.shared.notificationFeedback(.success)` with `HapticManager.shared.successFeedback()`. 

## HapticManager Errors

These errors are related to incorrect calls to the `HapticManager` class. The `HapticManager` doesn't have a method called `notificationFeedback` that accepts a parameter like `.success`.

```
/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:98:38 Value of type 'HapticManager' has no member 'notificationFeedback'
/Users/louismcauliffe/code/Pablo-timer-app/Pablo-timer-app/Features/TimerList/TimerListViewModel.swift:98:60 Cannot infer contextual base in reference to member 'success'
```

✅ This has been fixed by replacing all instances of `HapticManager.shared.notificationFeedback(.success)` with `HapticManager.shared.successFeedback()`.

## Import Related Errors

There are many errors related to missing imports in the files. For example:

```
cannot find 'TimerSequenceModel' in scope
cannot find 'TimerModel' in scope
cannot find 'RecurrenceRule' in scope
cannot find 'AppTheme' in scope
cannot find 'HapticManager' in scope
cannot find 'TimerService' in scope
```

### Updates Made

1. ✅ Fixed all `HapticManager.shared.notificationFeedback(.success)` calls by replacing them with `HapticManager.shared.successFeedback()`

2. ✅ Made `HapticManager` and its methods public to ensure it's accessible throughout the app:
   ```swift
   public class HapticManager {
       public static let shared = HapticManager()
       public func successFeedback() { ... }
       // etc.
   }
   ```

3. ✅ Made `TimerService` and its methods public to ensure it's accessible throughout the app:
   ```swift
   public final class TimerService {
       public static let shared = TimerService()
       public func scheduleTimerNotification(...) { ... }
       // etc.
   }
   ```

4. ✅ Added necessary imports to the TimerListViewModel:
   ```swift
   import Foundation
   import SwiftUI
   import SwiftData
   import Combine
   import UIKit
   import OSLog
   
   // Import models
   @preconcurrency import Pablo_timer_app
   ```

### Remaining Issues to Fix

The key remaining issues appear to be related to:

1. Imports and accessibility of model classes like `TimerModel`, `TimerSequenceModel`, and `RecurrenceRule`
2. Circular dependencies that may need to be restructured
3. Ensuring all components have proper access to the AppTheme singleton

The next step is to verify that these changes have resolved the issues with the app and make any additional adjustments needed 