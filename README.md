**Hotspot Host Onboarding App**

A Flutter app I built for the Hola9 internship assignment. This helps onboard new hosts through a simple questionnaire where they can select experiences they want to host and answer questions about their motivation.

**What I Built**

This is a two-screen onboarding flow:

<Screen 1 - Experience Selection>

Users pick from different hotspot experiences (like music events, sports, food tastings etc.) by tapping cards. I made the cards look like stamps with grayscale effect when not selected. There's also a text box where they can describe their ideal hotspot.

<Screen 2 - Question Screen>

Here users answer "Why do you want to host with us?" They can type, record audio, or record video - whatever they're comfortable with. The UI adapts as they record - buttons disappear once you've recorded something to keep things clean.

**Features**
<Core Requirements>

* Fetching experiences from the API

* Multi-select cards with visual feedback

* Text input with character limits (250 for screen 1, 600 for screen 2)

* Audio recording with live waveform

* Video recording with camera flip

* Playback for both audio and video

* Delete and retry options

* Navigation between screens

<Extra Stuff I Added>

* Responsive keyboard handling - the layout adjusts when keyboard opens so nothing gets hidden

* Custom stamp-style cards with tilted effect

* Wavy background pattern using Flutter's CustomPainter

* Animated white light effect on the Next button

* Confirmation dialogs for important actions

* Proper error messages when network fails

**Tech Choices**

*Riverpod for state management* - I went with Riverpod because it's type-safe and makes testing easier. Plus it's better than Provider for managing complex state like recording status.

*Dio for networking* - Used Dio instead of basic HTTP package because it has better error handling, request logging, and timeout configuration. Also added interceptors for debugging.

*Custom icons* - Drew custom icons using CustomPainter to match the design exactly. Could use Material Icons for simpler maintenance, but wanted to show I can work with custom graphics.

**How to Run**
<bash
flutter pub get
flutter run>

Make sure you have Flutter 3.x installed.

**Project Structure**

lib/
├── models/        # Data models for experiences and responses
├── providers/     # Riverpod state management
├── screens/       # The two main screens
├── services/      # API calls, audio, video services
├── utils/         # Colors, text styles, constants
└── widgets/       # Reusable UI components


**What I Learned**

This was my first time working with audio/video recording in Flutter. The tricky part was managing the recording state properly - making sure buttons update, waveforms animate, and cleanup happens when users cancel. Also learned a lot about responsive layouts and CustomPainter.

**Future Improvements**

*I identified these features for future versions:*

* Animate cards to first position when selected

* Next button width animation

* Save draft functionality

* Offline mode with local storage

I focused on getting core features working properly rather than adding animations that would need extra time without adding much functional value.

**API Used**

URL: 
https://staging.chamberofsecrets.8club.co/v1/experiences?active=true 
Method: GET


Screenshots


Demo Video
