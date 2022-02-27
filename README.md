# OpenConnectUI2

A Mac OSX menubar app to control [Openconnect VPN](https://www.infradead.org/openconnect/)

Copyright 2022 Ragnar Rova

Licensed under the MIT license

# Screenshots

<img width="192" alt="Screenshot 2022-02-25 at 07 49 35" src="https://user-images.githubusercontent.com/887132/155668965-aa700e12-c019-429b-9315-7c53e342ad44.png">

<img width="592" alt="Screenshot 2022-02-25 at 07 58 05" src="https://user-images.githubusercontent.com/887132/155669339-05ec600e-e30d-4674-8276-35d32b974a52.png">

# Installation

1. Install openconnect

```
brew install openconnect
```

2. Move the app to your Applications folder

3. On first launch, the tool asks to install a privileged helper which controls openconnect.

4. The app is just a menu bar app. Look for this icon in the menu bar:

<img width="32" alt="Screenshot 2022-02-25 at 07 59 52" src="https://user-images.githubusercontent.com/887132/155669653-5c88dbea-cc22-4baf-a286-3dd8dfea9afb.png">


5. Go to Preferences and fill out your login details. Password will be stored in your system keychain.

# Known issues

Does not invoke vpn-script to tear down a connection. Performs some network config cleanup of its own
which might not be enough. Please report any problems with this. 
