# Firestore Security Rules Setup

## Problem

The app is getting `PERMISSION_DENIED` errors from Firestore because security rules aren't set up for the new collections.

## Solution

### Step 1: Deploy Firestore Rules

1. **Using Firebase CLI (Recommended)**:

   ```bash
   # Install Firebase CLI if you haven't
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Initialize Firebase in your project (if not done)
   firebase init firestore

   # Deploy the rules
   firebase deploy --only firestore:rules
   ```

2. **Using Firebase Console (Alternative)**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `tracking-ed1ba`
   - Navigate to **Firestore Database** → **Rules**
   - Copy the content from `firestore.rules` file
   - Paste it in the rules editor
   - Click **Publish**

### Step 2: Verify Rules

After deploying, test the following operations:

- ✅ Read/write to `/statistics/{userId}`
- ✅ Read/write to `/finishedWorkouts/{userId}/finishedWorkoutsData/*`
- ✅ Read/write to `/users/{userId}/dailyReset/*`
- ✅ Read/write to `/meals/{userId}/waterData/*`

### New Collections Added

The following collections are now secured:

1. **`statistics/{userId}`** - Stores workout streaks and achievements
2. **`finishedWorkouts/{userId}/finishedWorkoutsData/{docId}`** - Stores completed workouts
3. **`users/{userId}/dailyReset/resetTracker`** - Tracks daily data resets

### Security Rules Summary

All collections follow the pattern:

- ✅ Authenticated users only
- ✅ Users can only access their own data
- ✅ Read and write permissions granted to document owners

## Testing

After deployment, restart the app and verify:

1. No more `PERMISSION_DENIED` errors in logs
2. Workout streak displays correctly
3. Achievements unlock properly
4. Weekly progress loads successfully

## Troubleshooting

If you still see permission errors:

1. Check that rules are published in Firebase Console
2. Verify the user is authenticated (`request.auth != null`)
3. Check that document paths match the rules patterns
4. Clear app data and re-login

## Production Considerations

For production, consider:

- Adding rate limiting
- Validating data types and structure
- Adding field-level security
- Implementing role-based access control (if needed)
