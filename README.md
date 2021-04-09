This script converts your audio into an uncompressed format and then encodes it into an uncompressed image, so that you can apply image/video filters to the data and databend it.
Also included are two other methods of doing this process, as well as the ability to quickly playback, bake/convert the output image back into a sharable audio file with the format of your choice.

# Setup:
Grab a copy of AHk Studio (You can use ALT+R to run this script ez): <br> https://github.com/maestrith/AHK-Studio/archive/master.zip <br>
Unzip `ffmpeg3.3.2.zip` and place `ffmpeg3.3.2.exe` in the same folder as this script.                                                                                                                    
Download, unzip and place all three of these .exes in the same folder as well                                                                                                                                                          
https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffmpeg-4.2.1-win-32.zip                                                                                                       
https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffplay-4.2.1-win-32.zip                                                                                          
https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffprobe-4.2.1-win-32.zip

# Modes:
`EnableSecretGlitch` attempts to calculate the dimensions, not complete but yields alternative results. <br>
`EnableFFmpegLuxification` applies internal Reverse Sonificiation inside of ffmpeg through pipes. <br>
`Default` is the brute force method of this process; which is enabled when above are both disabled or set to `0`.

# Hotkeys:
`F10` Playback Your Image/Audio <br>
`F9`  Bake/Convert Your Image Back Into Audio <br>
`F8`  Kill Script <br>

# Video Tutorial Coming Soon...
