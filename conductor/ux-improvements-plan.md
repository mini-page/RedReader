# UX Improvements Plan: iReader Home Screen

## 1. Header & Typography
*   **Action**: Modify the header text in `home_screen.dart`.
*   **Changes**:
    *   Change the 'i' in 'iReader' to use the accent color (Red).
    *   Reduce the letter spacing to 1.

## 2. Continue Reading Card
*   **Action**: Adjust the layout and style in `home_screen.dart`.
*   **Changes**:
    *   Add bottom padding to the progress bar to make it float inside the card.
    *   Increase the thickness of the progress bar to match the modern slider aesthetic.
    *   Slightly reduce the size of the play icon.
    *   Adjust the overall padding and shape of the card for a refined look.

## 3. Action Buttons (Paste & Upload)
*   **Action**: Unify styling and update interaction logic in `home_screen.dart`.
*   **Changes**:
    *   Ensure both the "Paste text" and "Upload file" cards have identical size, shape, and internal spacing.
    *   **Paste Text Logic**: Remove the popup dialog. Tapping the card will immediately push the `/preview` route with empty fields, allowing the user to paste and edit directly on the Preview Screen.
    *   **Upload File Logic**: Update the `_pickFiles` method. Introduce a "matrix rail" extraction animation while parsing the document. Once extraction is complete, redirect to the `/preview` route so users can review or edit the extracted text and set a title.

## 4. Demo Banner Management
*   **Action**: Ensure the demo banner disappears after first use.
*   **Changes**:
    *   Add a `hasRunDemo` boolean to `AppSettings` and `SettingsController`.
    *   In `HomeScreen`, hide the demo banner if `hasRunDemo` is true.
    *   When the demo finishes (handled in `ReaderController`), ensure `hasRunDemo` is toggled on, allowing the user to see the analytical card and returning to a clean home screen without the banner.

## 5. Library Search & Sort Integration
*   **Action**: Implement search and sorting mechanisms in `home_screen.dart`.
*   **Changes**:
    *   **Search Bar**: Add a `TextField` above the library list. Filtering logic will match the query against session titles and content.
    *   **Sort Button**: Place an icon button next to the search bar.
    *   **Sort Logic**: Create an enum `SortType { size, progress, title, date }`. Track current sort type and order (ascending/descending).
    *   **Sort Popup**: Tapping the sort button opens a popup (styled like the quick settings popup) listing the four options. Tapping an option selects it (ascending by default); tapping it again reverses the order (showing an up/down arrow indicator).
    *   Apply the selected sort and filter to the `sessions` list before rendering the cards.

## Conclusion
This plan ensures all requested UX features are systematically implemented, resulting in a cleaner, more interactive, and highly polished home screen experience.