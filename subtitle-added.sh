#!/bin/bash

# Miyoo Mini Plus Video Converter with Burned Subtitles
INPUT_FILE="$1"
SUBTITLE_FILE="$2"  # Optional .srt file
OUTPUT_NAME="${3:-converted_$(basename "$INPUT_FILE" .mkv).mp4}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 input_video.mkv [subtitle_file.srt] [output_name]"
    exit 1
fi

echo "Converting $INPUT_FILE with burned subtitles..."

# Build subtitle filter
if [ -n "$SUBTITLE_FILE" ] && [ -f "$SUBTITLE_FILE" ]; then
    SUBTITLE_FILTER="subtitles='$SUBTITLE_FILE':force_style='FontSize=12,PrimaryColour=&Hffffff&,OutlineColour=&H000000&,Outline=1'"
    VIDEO_FILTER="scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black,$SUBTITLE_FILTER"
    echo "Using external subtitle file: $SUBTITLE_FILE"
elif ffprobe -v quiet -select_streams s:0 -show_entries stream=codec_name "$INPUT_FILE" 2>/dev/null; then
    # Extract embedded subtitles from MKV
    VIDEO_FILTER="scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black,subtitles='$INPUT_FILE':si=0:force_style='FontSize=12,PrimaryColour=&Hffffff&,OutlineColour=&H000000&,Outline=1'"
    echo "Using embedded subtitles from video file"
else
    VIDEO_FILTER="scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black"
    echo "No subtitles found or specified"
fi

ffmpeg -i "$INPUT_FILE" \
    -vf "$VIDEO_FILTER" \
    -c:v libx264 \
    -crf 28 \
    -preset medium \
    -profile:v baseline \
    -level 3.0 \
    -maxrate 600k \
    -bufsize 600k \
    -c:a aac \
    -b:a 48k \
    -ar 22050 \
    -ac 1 \
    -f mp4 \
    -movflags +faststart \
    "$OUTPUT_NAME"

if [ $? -eq 0 ]; then
    echo "Conversion completed with burned subtitles: $OUTPUT_NAME"
    echo "Subtitles are now permanent part of the video"
else
    echo "Conversion failed"
fi