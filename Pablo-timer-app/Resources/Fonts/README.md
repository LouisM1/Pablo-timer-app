# Adding Poppins Font to the Project

To complete the font integration, follow these steps:

## 1. Download the Poppins Font

Download the Poppins font from Google Fonts: [Poppins on Google Fonts](https://fonts.google.com/specimen/Poppins)

## 2. Add Font Files to the Project

1. Extract the ZIP file
2. Add the following TTF files to this directory:
   - Poppins-Regular.ttf
   - Poppins-Medium.ttf
   - Poppins-SemiBold.ttf
   - Poppins-Bold.ttf
   - Poppins-Light.ttf
   - Poppins-Thin.ttf

## 3. Update Info.plist

Add the following to your Info.plist file:

```xml
<key>UIAppFonts</key>
<array>
    <string>Fonts/Poppins-Regular.ttf</string>
    <string>Fonts/Poppins-Medium.ttf</string>
    <string>Fonts/Poppins-SemiBold.ttf</string>
    <string>Fonts/Poppins-Bold.ttf</string>
    <string>Fonts/Poppins-Light.ttf</string>
    <string>Fonts/Poppins-Thin.ttf</string>
</array>
```

## 4. Update FontSystem.swift

If you have actual font files in the project, update the `poppins` method in `FontSystem.swift` to use the custom font:

```swift
static func poppins(size: CGFloat, weight: Weight = .regular) -> Font {
    // Use the actual custom fonts
    return Font.custom("Poppins-\(weight.value)", size: size)
}
```

## 5. Rebuild and Run

After making these changes, rebuild and run your app to see the Poppins font in action. 