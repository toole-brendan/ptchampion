Implementation Plan – Align iOS styling with the current Web module
===================================================================
Pre-flight (branch safety)
  a. git status – verify you have no uncommitted changes.
  b. git branch --show-current – confirm you are NOT on main.
  c. If you are on main:
   i. git pull origin main (to ensure up-to-date).
   ii. git checkout -b feat/ios-style-sync (or similar).
  d. Push the branch immediately (git push -u origin feat/ios-style-sync) so CI / teammates can see progress.
Inventory & source-of-truth (Web)
1.1 Fonts – located in web/public/fonts/futura/*.
  1.2 Colors – inspect:
   • web/src/components/ui/* (button, card, alert, etc.)
   • web/src/styles (if present)
   • Hard-coded hex values in component files (run rg "#[0-9a-fA-F]{6}" web/src/components | sort | uniq).
  1.3 Typography scale – check web/src/components/ui/typography.tsx.
  1.4 Container paddings / max-widths – DesktopLayout.tsx, MobileLayout.tsx, card.tsx.
  1.5 Card visuals – card.tsx (radius, shadow, border).
2. Create a clean styling surface on iOS (ignore existing design-token system)
 2.1 In Xcode, inside ptchampion create a new group Styling (alongside Models, Services, Views, etc.).
  2.2 Add five new Swift files:
   • AppColors.swift
   • AppFonts.swift
   • Typography.swift
   • ContainerStyle.swift
   • CardStyle.swift
Fonts – manual copy & registration
  3.1 Drag-and-drop the entire futura/ font folder from web/public/fonts to ios/ptchampion/Resources/Fonts (❗ ensure "Copy items if needed" & "Add to target: ptchampion" are checked).
3.2 Update ptchampion/Info.plist → Fonts provided by application array with each .ttf/.otf.
  3.3 Implement AppFonts.swift
   • Add an enum AppFont with static helpers, e.g. static let regular = Font.custom("FuturaPT-Book", size:).
   • Provide convenience methods for dynamic type, e.g. func appFont(_ style: TypographyStyle) -> some View.
  3.4 Write a small unit test in PTChampionTests that loads each font via UIFont(name:size:) to catch registration issues in CI.
Colors – 1-for-1 translation
  4.1 From step 1.2, list every unique hex → create AppColors.swift with extension Color { static let primary = Color(hex:"#FF5733") … }.
  4.2 Add a helper init(hex:String) (parse hex to RGB).
  4.3 Snapshot test (DesignSystemSnapshotTests) for a simple Color grid to ensure no typos.
5. Typography scale – mirror web
 5.1 Inspect typography.tsx for font-size / line-height pairs.
  5.2 In Typography.swift:
   • enum TypographyStyle { case h1, h2, body, caption, … }
   • Each case returns (font: Font, letterSpacing: CGFloat, lineHeight: CGFloat?).
   • Provide a ViewModifier TypographyModifier(style:) and a Text extension .typography(_:).
Container & layout constants
  6.1 In ContainerStyle.swift define spacing constants:
   struct Container { static let horizontalPadding: CGFloat = 16 … } matching layout.tsx.
  6.2 Create a ViewModifier .container() that sets .padding(.horizontal, Container.horizontalPadding) and .frame(maxWidth: Container.maxWidth).
Card styling
  7.1 Translate radius, shadow, border from card.tsx → CardStyle.swift:
   struct CardModifier: ViewModifier { /* cornerRadius, shadow, border */ }.
   extension View { func card() -> some View { modifier(CardModifier()) }.
8. Refactor existing SwiftUI components to adopt new styles
  8.1 Search-and-replace fonts:
   • For each Text where .font(.system(...)) replace with .typography(.body) or appropriate.
  8.2 Replace color literals with AppColors.
  8.3 Wrap high-level screens (DashboardView, ProfileView, etc.) root VStack/HStack in .container().
  8.4 Change any existing PTCard usage to .card(); if PTCard is deeply integrated, add an initializer to forward to the new modifier.
Update previews & snapshots
  9.1 For every SwiftUI preview in DesignSystemPreview.swift and key views, ensure they compile with new modifiers.
  9.2 Re-run PTChampionTests snapshot targets; accept new baselines once visually verified.
10. Regression checklist
  □ App launches on iPhone SE, 14 Pro Max, iPad.
  □ Dynamic type still works (rotate font sizes).
  □ Dark mode colors render correctly (if supported).
  □ All fonts appear in Settings → General → Fonts (debug tool).
  □ Cards & containers match spacing observed in web screenshots.
Commit cadence
  • Commit after steps 3, 4, 5 separately (feat: add futura font, feat: ios color palette, …) for easier code review.
  • Push and open a draft PR early; attach side-by-side screenshots (web vs iOS).
  • Request design/PM review before merging.
Cleanup & merge
  • Once approved, git checkout main && git pull origin main && git merge --no-ff feat/ios-style-sync.
  • Tag release vX.Y.Z-ios-style-sync if required by CI/CD.