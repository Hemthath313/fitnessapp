# Video Optimization Guide

## Why Optimize Videos?

Your current videos are around **1MB each**, which can quickly add up:
- 5 videos = ~5MB
- 20 videos = ~20MB
- 50 videos = ~50MB

This increases your app size significantly! Optimized videos can be **50-70% smaller** while maintaining good quality.

## Quick Optimization

### Option 1: Using Python Script (Recommended)

```bash
python3 scripts/optimize_videos.py
```

### Option 2: Using Bash Script

```bash
./scripts/optimize_videos.sh
```

### Option 3: Manual Optimization with FFmpeg

If you prefer to optimize videos manually:

```bash
# Install ffmpeg first
brew install ffmpeg  # macOS
# or
sudo apt-get install ffmpeg  # Linux

# Optimize a single video
ffmpeg -i "assets/videos/barbell curl.mp4" \
  -vf scale=720:-2 \
  -c:v libx264 \
  -preset fast \
  -crf 28 \
  -c:a aac \
  -b:a 64k \
  -movflags +faststart \
  -r 24 \
  "assets/videos/barbell curl_optimized.mp4"
```

## Optimization Settings Explained

- **Resolution**: 720p max (perfect for mobile screens)
- **CRF 28**: Good quality/size balance (lower = better quality, 23-28 recommended)
- **24fps**: Smooth enough for exercise videos
- **H.264 codec**: Best compatibility across devices
- **Fast preset**: Good balance between encoding speed and compression

## Expected Results

- **Original**: ~1MB per video
- **Optimized**: ~300-500KB per video
- **Reduction**: 50-70% smaller files
- **Quality**: Still looks great on mobile devices!

## After Optimization

1. Review the optimized videos in `assets/videos/optimized/`
2. If quality looks good, replace originals:
   ```bash
   mv assets/videos/optimized/*.mp4 assets/videos/
   ```
3. Delete the optimized directory:
   ```bash
   rm -rf assets/videos/optimized
   ```

## Alternative: Lower Quality (Even Smaller)

If you want even smaller files (but lower quality):

```bash
ffmpeg -i input.mp4 \
  -vf scale=480:-2 \
  -c:v libx264 \
  -preset fast \
  -crf 32 \
  -c:a aac \
  -b:a 48k \
  -r 20 \
  output.mp4
```

This will create videos around **150-300KB** each, but quality will be lower.

## Tips

1. **Test on device**: Always test optimized videos on a real device
2. **Keep originals**: Backup your original videos before optimizing
3. **Batch process**: Use the scripts to optimize all videos at once
4. **Monitor quality**: Check that the quality is acceptable for your use case

