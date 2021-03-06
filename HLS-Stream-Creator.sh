#!/bin/bash
#
# A very simple BASH script to take an input video and split it down into Segments 
# before creating an M3U8 Playlist, allowing the file to be served using HLS
#
#

######################################################################################
#
# Copyright (c) 2013, Ben Tasker
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
#   Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
# 
#   Neither the name of Ben Tasker nor the names of his
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
######################################################################################

# Basic config
OUTPUT_DIRECTORY=${OUTPUT_DIRECTORY:-'./output'}

# Change this if you want to specify a path to use a specific version of FFMPeg
FFMPEG=${FFMPEG:-'ffmpeg'}

# Number of threads which will be used for transcoding. With newer FFMPEGs and x264
# encoders "0" means "optimal". This is normally the number of CPU cores.
NUMTHREADS=${NUMTHREADS:-"0"}

# Video codec for the output video. Will be used as an value for the -vcodec argument
VIDEO_CODEC=${VIDEO_CODEC:-"libx264"}

# Video codec for the output video. Will be used as an value for the -acodec argument
AUDIO_CODEC=${AUDIO_CODEC:-"libfdk_aac"}

# Additional flags for ffmpeg
FFMPEG_FLAGS=${FFMPEG_FLAGS:-""}

# Lets put our functions here


## Output the script's CLI Usage
#
#
function print_usage(){

cat << EOM
HTTP Live Stream Creator
Version 1

Copyright (C) 2013 B Tasker, D Atanasov
Released under BSD 3 Clause License
See LICENSE


Usage: HLS-Stream-Creator.sh inputfile segmentlength(seconds) [outputdir='./output']

EOM

exit

}

# Get the input data

# Basic Usage is going to be
# cmd.sh inputfile segmentlength 

INPUTFILE=${INPUTFILE:-$1}
SEGLENGTH=${SEGLENGTH:-$2}
if ! [ -z "$3" ]
then
  OUTPUT_DIRECTORY=$3
fi

# Check we've got the arguments we need
if [ "$INPUTFILE" == "" ] || [ "$SEGLENGTH" == "" ]
then
  print_usage
fi

# FFMpeg is a pre-requisite, so let check for it
if hash $FFMPEG 2> /dev/null
then
  # FFMpeg exists
  echo "ffmpeg command found.... continuing"
else
  # FFMPeg doesn't exist, uh-oh!
  echo "Error: FFmpeg doesn't appear to exist in your PATH. Please addresss and try again"
  exit 1
fi


# Now we want to make sure out input file actually exists
if ! [ -f "$INPUTFILE" ]
then
  echo "Error: You gave me an incorrect filename. Please re-run specifying something that actually exists!"
  exit 1
fi

# Check output directory exists otherwise create it
if [ ! -w $OUTPUT_DIRECTORY ]
then
  echo "Creating $OUTPUT_DIRECTORY"
  mkdir -p $OUTPUT_DIRECTORY
fi

# Pulls file name from INPUTFILE which may be an absolute or relative path.
INPUTFILENAME=${INPUTFILE##*/}

# Finally, lets build the output filename format
OUT_NAME=$INPUTFILENAME"_%05d.ts"

# Processing Starts
$FFMPEG -i "$INPUTFILE" \
  -loglevel error -y \
  -vcodec "$VIDEO_CODEC" \
  -acodec "$AUDIO_CODEC" \
  -threads "$NUMTHREADS" \
  -map 0 \
  -flags \
  -global_header \
  -f segment \
  -segment_list "$OUTPUT_DIRECTORY/$INPUTFILENAME.m3u8" \
  -segment_time "$SEGLENGTH" \
  -segment_format mpeg_ts \
  $FFMPEG_FLAGS \
  $OUTPUT_DIRECTORY/"$OUT_NAME" || exit 1
