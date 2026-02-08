# App Size Management Guide

## Current Situation

Your app currently has:
- **Chest videos**: ~8.6 MB (11 videos)
- **Biceps videos**: ~13 MB (13 videos)
- **Total**: ~21.6 MB just for videos

As you add more body parts (legs, triceps, abs, etc.), this will grow significantly:
- 5 body parts × 10-15 videos each = **50-75 videos**
- At current sizes: **50-100 MB** just for videos
- This can make your app **100-150 MB+** total size

## Solutions

### 1. **Video Optimization (RECOMMENDED - Do This First!)**

Optimize all videos to reduce size by 50-70%:

```bash
python3 scripts/optimize_videos.py
```

**Expected Results:**
- Current: ~21.6 MB → Optimized: ~7-10 MB (60-70% reduction)
- With 50 videos: ~100 MB → ~30-40 MB
- Quality: Still looks great on mobile devices!

**Settings Used:**
- Resolution: 720p max (perfect for mobile)
- CRF: 28 (good quality/size balance)
- Frame rate: 24fps (smooth enough)
- Codec: H.264 (best compatibility)

### 2. **Lower Quality for Even Smaller Size**

If you need even smaller files, you can use more aggressive settings:

```bash
# For 480p videos (150-300KB each)
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

**Trade-off:** Lower quality but much smaller files.

### 3. **Lazy Loading / On-Demand Download**

Instead of bundling all videos in the app, download them on-demand:

**Pros:**
- Initial app size: ~10-20 MB
- Videos downloaded only when needed
- Can update videos without app update

**Cons:**
- Requires internet connection
- Need cloud storage (Firebase Storage, AWS S3, etc.)
- More complex implementation

**Implementation:**
```dart
// Download video when user opens exercise
Future<String> downloadVideo(String videoUrl) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$videoName.mp4');
  
  if (await file.exists()) {
    return file.path; // Use cached version
  }
  
  // Download from cloud
  final response = await http.get(Uri.parse(videoUrl));
  await file.writeAsBytes(response.bodyBytes);
  return file.path;
}
```

### 4. **Hybrid Approach (Best Balance)**

Combine optimization + selective bundling:

1. **Bundle only essential videos** (most popular exercises)
2. **Optimize all bundled videos** (reduce size by 60-70%)
3. **Download others on-demand** (less popular exercises)

**Example:**
- Bundle: Top 3-5 exercises per body part (optimized)
- Download: Remaining exercises on-demand

### 5. **Video Compression Tips**

Before adding videos:
- Record at 720p max (not 1080p or 4K)
- Keep videos short (10-30 seconds for exercises)
- Remove audio if not needed (saves ~10-20%)
- Use efficient codecs (H.264)

## Recommended Strategy

### Phase 1: Immediate (Do Now)
1. ✅ Optimize all existing videos
2. ✅ Test quality on device
3. ✅ Replace originals with optimized versions

### Phase 2: Before Adding More
1. Set video quality standards (720p max, 24fps)
2. Optimize new videos before adding
3. Monitor app size as you add more

### Phase 3: If App Gets Too Large (>100MB)
1. Implement lazy loading for less popular exercises
2. Keep only top exercises bundled
3. Download others on-demand

## Quick Commands

### Optimize All Videos
```bash
python3 scripts/optimize_videos.py
```

### Check Current Video Sizes
```bash
du -sh assets/videos/*/
```

### Check Total App Size (after build)
```bash
# iOS
ls -lh build/ios/ipa/*.ipa

# Android
ls -lh build/app/outputs/flutter-apk/*.apk
```

## Size Targets

| App Size | Status | Action |
|----------|--------|--------|
| < 50 MB | ✅ Good | Continue current approach |
| 50-100 MB | ⚠️ Getting large | Optimize all videos |
| 100-150 MB | ⚠️ Large | Consider lazy loading |
| > 150 MB | ❌ Too large | Implement on-demand downloads |

## Best Practices

1. **Always optimize videos** before adding to app
2. **Test on real device** to ensure quality is acceptable
3. **Monitor app size** regularly
4. **Keep videos short** (10-30 seconds for exercises)
5. **Remove unnecessary audio** if not needed
6. **Use appropriate resolution** (720p is perfect for mobile)

## Next Steps

1. Run optimization script on all videos
2. Review optimized videos for quality
3. Replace originals if quality is good
4. Continue optimizing new videos before adding them

