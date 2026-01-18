# Worker Profile Account Information Card Resize

## Changes Made

### File: `lib/screens/worker_profile_screen.dart`

#### 1. **Account Information Card Sizing**
- **Padding**: Reduced from `20` to `16` for better fit
- **Border Radius**: Reduced from `24` to `20` for better proportions
- **Icon Size**: Reduced from `20` to `18`
- **Title Font Size**: Reduced from `18` to `16`

#### 2. **Info Row Improvements**
- **Vertical Padding**: Reduced from `12` to `10` for tighter spacing
- **Font Size**: Reduced from `14` to `13` for better fit
- **Value Text**: Added `Flexible` widget to handle long text properly
- **Text Alignment**: Value text now right-aligned with `textAlign: TextAlign.end`

#### 3. **Member Since Row**
- **Font Size**: Reduced from `14` to `13` for consistency
- **Top Padding**: Reduced from `12` to `10`

#### 4. **Card Positioning**
- **Top Position**: Adjusted from `260` to `240` for better overlap
- **Horizontal Margins**: Reduced from `20` to `16` for better screen fit

#### 5. **Scrollable Content Padding**
- **Top Padding**: Reduced from `160` to `140` to accommodate the resized card

## Layout Improvements

### Before:
- Large padding and spacing
- Text could overflow on smaller screens
- Card took up too much vertical space

### After:
- Compact, well-proportioned layout
- Text wraps properly with Flexible widget
- Better use of screen space
- Consistent font sizing throughout
- Proper alignment of labels and values

## Visual Changes

```
Account Information Card:
├── Icon + Title (smaller, more compact)
├── Role: Worker
├── Service Type: Home Repairs
├── City: Not Set
├── Region: Not Set
└── Member Since: 0000
```

All rows now have:
- Consistent 10px vertical padding
- 13px font size
- Proper text alignment
- Better visual hierarchy

## Responsive Design

The card now:
- Fits better on smaller screens
- Handles long text values gracefully
- Maintains proper spacing on all devices
- Looks proportional to the rest of the profile

## Testing

The profile page should now display:
1. Header with profile picture
2. Account Information card (properly sized and positioned)
3. Settings section below
4. Logout button at the bottom

All elements should fit without overlapping or excessive spacing.
