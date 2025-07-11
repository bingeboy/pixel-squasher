# Pixel Squasher

A simple FFmpeg script to convert videos for optimal playback on the Miyoo Mini Plus handheld gaming device.

## Overview

The Miyoo Mini Plus has specific video format requirements due to its limited ARM processor and 480x320 display. This script automatically converts videos to the correct specifications for smooth playback.

## Features

- Converts videos to Miyoo Mini Plus compatible format
- Maintains aspect ratio with letterboxing
- Optimizes for low-power ARM processor
- Supports batch conversion
- Cross-platform (Linux, macOS, Windows)

## Requirements

- [FFmpeg](https://ffmpeg.org/download.html) installed and accessible from command line
- Bash shell (Linux/macOS) or Command Prompt (Windows)

## Installation

1. Clone this repository:

```bash
git clone https://github.com/yourusername/miyoo-video-converter.git
cd miyoo-video-converter
```

2. Make the script executable (Linux/macOS):
```bash
chmod +x convert_for_miyoo.sh
```
## Usage
Basic Conversion
```bash
bash./convert_for_miyoo.sh input_video.mp4
```

Creates converted_input_video.mp4 in the same directory.

## Custom Output Name
```bash
bash./convert_for_miyoo.sh input_video.mp4 my_movie.mp4
```
## Batch Conversion
Convert all MP4 files in a directory
```bash
for file in /path/to/videos/*.mp4; do
    ./convert_for_miyoo.sh "$file"
done
```

## Windows Users

Use the included convert_for_miyoo.bat file:
```
cmdconvert_for_miyoo.bat input_video.mp4 output_video.mp4
```
