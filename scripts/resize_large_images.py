#!/usr/bin/env python3
"""
Resize Large Images Script
Resizes images to their actual display dimensions to reduce file size.
Most images in the app are displayed at max 400-500px width.
"""

import os
import sys
import shutil
from pathlib import Path

def check_pillow():
    """Check if Pillow is installed"""
    try:
        from PIL import Image
        return True
    except ImportError:
        return False

def install_pillow():
    """Try to install Pillow"""
    print("📦 Pillow not found. Attempting to install...")
    try:
        import subprocess
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'Pillow'], 
                      check=True, capture_output=True)
        print("✅ Pillow installed successfully!")
        return True
    except Exception:
        print("❌ Failed to install Pillow automatically.")
        print("💡 Please install manually: pip3 install Pillow")
        return False

def get_file_size(filepath):
    """Get file size in KB"""
    return os.path.getsize(filepath) / 1024

def resize_image(input_path, output_path, max_width=800, max_height=800, quality=80):
    """Resize image to max dimensions while maintaining aspect ratio"""
    try:
        from PIL import Image
        
        img = Image.open(input_path)
        original_size = img.size
        
        # Calculate new size maintaining aspect ratio
        ratio = min(max_width / original_size[0], max_height / original_size[1])
        if ratio >= 1.0:
            # Image is already smaller, just optimize
            new_size = original_size
        else:
            new_size = (int(original_size[0] * ratio), int(original_size[1] * ratio))
        
        # Resize image
        if new_size != original_size:
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Save with optimization
        if input_path.suffix.lower() == '.webp':
            img.save(output_path, 'WEBP', quality=quality, method=6)
        elif input_path.suffix.lower() in ['.jpg', '.jpeg']:
            if img.mode == 'RGBA':
                rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                rgb_img.paste(img, mask=img.split()[3] if len(img.split()) == 4 else None)
                img = rgb_img
            img.save(output_path, 'JPEG', quality=quality, optimize=True, progressive=True)
        elif input_path.suffix.lower() == '.png':
            img.save(output_path, 'PNG', optimize=True, compress_level=9)
        else:
            return False
        
        return True
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
        return False

def main():
    print("🖼️  Starting large image resizing...\n")
    
    # Check Pillow
    if not check_pillow():
        if not install_pillow():
            sys.exit(1)
    
    from PIL import Image
    
    # Setup paths
    images_dir = Path("assets/images")
    
    if not images_dir.exists():
        print(f"❌ Images directory not found: {images_dir}")
        sys.exit(1)
    
    # Define resize targets for different image types
    resize_targets = {
        # Carousel images - typically shown at 400-500px width
        'carousel': {'max_width': 800, 'max_height': 600, 'quality': 75},
        # Boarding images - full screen but can be optimized
        'boarding': {'max_width': 1200, 'max_height': 1600, 'quality': 80},
        # Workout images - shown as cards, smaller
        'workout': {'max_width': 600, 'max_height': 400, 'quality': 75},
        # Food images - shown in cards
        'food': {'max_width': 600, 'max_height': 600, 'quality': 80},
        # Logos and icons - keep small
        'logo': {'max_width': 512, 'max_height': 512, 'quality': 85},
        # Default
        'default': {'max_width': 800, 'max_height': 800, 'quality': 80},
    }
    
    # Find large images (>300 KB)
    large_images = []
    for img_file in images_dir.iterdir():
        if img_file.is_file() and img_file.suffix.lower() in ['.webp', '.jpg', '.jpeg', '.png']:
            size_kb = get_file_size(img_file)
            if size_kb > 300:  # Only resize images larger than 300 KB
                large_images.append((img_file, size_kb))
    
    if not large_images:
        print("✅ No large images found to resize!")
        return
    
    # Sort by size (largest first)
    large_images.sort(key=lambda x: x[1], reverse=True)
    
    print(f"🖼️  Found {len(large_images)} large image(s) to resize\n")
    
    total_original = 0
    total_optimized = 0
    processed = 0
    
    for img_file, original_size_kb in large_images:
        print(f"📷 Resizing: {img_file.name} ({original_size_kb:.1f} KB)")
        
        # Determine resize settings based on filename
        if 'carousel' in img_file.name.lower():
            settings = resize_targets['carousel']
        elif 'boarding' in img_file.name.lower():
            settings = resize_targets['boarding']
        elif 'workout' in img_file.name.lower():
            settings = resize_targets['workout']
        elif any(food in img_file.name.lower() for food in ['food', 'breakfast', 'lunch', 'dinner', 'snack', 'diet', 'jpeg']):
            settings = resize_targets['food']
        elif 'logo' in img_file.name.lower() or 'icon' in img_file.name.lower():
            settings = resize_targets['logo']
        else:
            settings = resize_targets['default']
        
        total_original += original_size_kb
        
        # Create temporary file
        temp_file = img_file.with_suffix('.tmp' + img_file.suffix)
        
        if resize_image(img_file, temp_file, 
                       max_width=settings['max_width'],
                       max_height=settings['max_height'],
                       quality=settings['quality']):
            new_size_kb = get_file_size(temp_file)
            
            if new_size_kb < original_size_kb:
                shutil.move(str(temp_file), str(img_file))
                total_optimized += new_size_kb
                reduction = ((original_size_kb - new_size_kb) / original_size_kb) * 100
                print(f"   ✅ Resized: {original_size_kb:.1f} KB → {new_size_kb:.1f} KB ({reduction:.1f}% reduction)\n")
                processed += 1
            else:
                temp_file.unlink()
                total_optimized += original_size_kb
                print(f"   ℹ️  No improvement: {original_size_kb:.1f} KB\n")
        else:
            if temp_file.exists():
                temp_file.unlink()
            total_optimized += original_size_kb
            print(f"   ❌ Failed to resize\n")
    
    # Summary
    print("=" * 50)
    print("✨ Resizing complete!")
    print(f"📊 Processed: {processed} images resized")
    print(f"📦 Total size: {total_original:.1f} KB → {total_optimized:.1f} KB")
    if total_original > 0:
        space_saved = total_original - total_optimized
        percent_saved = (space_saved / total_original) * 100
        if space_saved > 0:
            print(f"💾 Space saved: {space_saved:.1f} KB ({percent_saved:.1f}%)")
    print("\n✅ Large images have been resized!")

if __name__ == "__main__":
    main()

