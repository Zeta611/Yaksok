# Yaksok

## Installation
Support for package managers will be added.

## Documentation
Documentation will be added.

## Example
```swift
User.login(username: username, password: password)
  .flatMap { user in
    user.fetchFriends()
  }
  .done { friends in
    // Do something with the user's friends
  }
  .catch { error in
    // do something with the error
  }
```

## License
Yaksok is available under the MIT license. See the LICENSE file for more info.
