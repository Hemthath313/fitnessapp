# Workout Videos Directory

Place your workout videos in this directory. The app will automatically map exercise names to video files.

## Video File Naming

The app uses intelligent matching to find videos based on exercise names. You can name your videos in one of these ways:

1. **By Exercise Name** (Recommended): Name your video files using the exercise name with underscores
   - Example: `bench_press.mp4`, `push_up.mp4`, `barbell_curl.mp4`
   - The app will automatically match these to exercises

2. **Custom Mapping**: You can create a JSON file at `assets/json/video_mappings.json` with custom mappings:
   ```json
   {
     "bench press": "assets/videos/my_bench_press_video.mp4",
     "push up": "assets/videos/pushup.mp4"
   }
   ```

## Supported Video Formats

- `.mp4` (Recommended)
- `.mov`
- `.avi`

## How It Works

1. The app fetches exercise data from the API (or uses cached data)
2. For each exercise, it tries to find a matching local video file
3. If a local video is found, it plays the video
4. If no local video is found, it falls back to the GIF from the API

## Adding Videos

1. Place your video files in this directory (`assets/videos/`)
2. Name them based on the exercise name (e.g., `bench_press.mp4`)
3. The app will automatically detect and use them
4. No code changes needed!

## Example Video Names

- `bench_press.mp4`
- `push_up.mp4`
- `barbell_curl.mp4`
- `dumbbell_fly.mp4`
- `tricep_dip.mp4`
- `squat.mp4`
- `deadlift.mp4`
- `pull_up.mp4`

The app will match these automatically based on the exercise names from the API.

