# Flutter AI integration

Firestore remains the source of truth. The app uses the backend's `/ai` routes
with the signed-in user's Firebase ID token; it does not use the backend's
separate SQL challenge/project workflow.

## Run locally

From `backend/`, create and activate a Python virtual environment, then install
`requirements.txt`. Configure `FIREBASE_PROJECT_ID=janyukti-1cbba` and
`FIREBASE_AUTH_MODE=required` in `backend/.env`. For a local demo only, the backend
also supports `FIREBASE_AUTH_MODE=off`. No Firebase service-account file is needed
for token verification. See `backend/app/config.py` for the other settings.

Run `python -m app.seed` to initialize university expertise profiles, optionally
`python -m scripts.ingest_openalex`, and start `python main.py` on port 8000.

Debug Flutter builds default to `http://localhost:8000` on iOS simulators and
`http://10.0.2.2:8000` on Android emulators. Android debug builds allow local HTTP;
iOS declares local networking access. For a phone on the same network, use a
reachable host (prefer a local `.local` hostname for iOS HTTP development):

```sh
flutter run --dart-define=AI_API_URL=http://your-mac.local:8000
```

Allow local network access when prompted and ensure the backend binds to
`0.0.0.0`. Release builds require an explicit `AI_API_URL` pointing to the deployed
HTTPS backend. Restart the app after changing Dart defines. For Flutter web,
configure the backend's `CORS_ORIGINS` to include the app's origin.

## Citizen submission

After a title and description are entered, a debounced `/ai/analyze` request
suggests the category and priority. Edits, including voice transcripts, invalidate
old results. The category remains editable; an explicit category choice takes
precedence over AI. Draft analysis uses `index: false`.

The chosen category and AI priority are saved in the existing Firestore challenge
fields. If AI fails, submission offers an explicit choice to go back or submit
with the selected category and Medium priority. No draft is added to the duplicate
index and there is no citizen duplicate dialog.

## Admin assignment

Before assignment, the duplicate review syncs the current Firestore challenge
list through `/ai/index/sync` in non-pruning batches, then calls `/ai/duplicates`
with the current challenge excluded. This includes older submissions and refreshes
statuses. Deleted Firestore IDs are filtered out of displayed matches. Similar
challenges can be opened for review; they are suggestions, not automatic rejections.
Assignment waits for the check to succeed, and failure offers a retry.

University recommendations use `/ai/match`, with active canonical universities
linked to approved university accounts. The backend's scores and reasons appear in
the existing ranking cards. Assignment uses the returned canonical Firestore ID;
external directory profiles cannot be assigned. Pull to refresh reruns both checks.
The service accepts at most 500 eligible universities per matching request.

## Verification and deployment prerequisites

Run `flutter test test/ai_integration_test.dart` for request contracts, auth headers,
error/timeout handling, index batching, ID mapping and category/priority persistence.

A live smoke test needs the backend running, a signed-in citizen, an approved admin,
an active university with an approved linked account, and deployed Firestore rules
that support the app's existing challenges/universities workflow. The checked-in
`firestore.rules` currently covers only users and organizations; this integration
does not deploy or replace database rules. The SQL demo accounts are separate from
Firebase app accounts.
