#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance,Force ;Self Explenatory

;                    ~Audio2Image.ahk v1.88~
;
; Encode/Convert uncompressed audio into an uncompressed image!
;     Databend/reverse sonify in GIMP, Photoshop or more!
;~~~~~~~~~~~~~~~~~~~~~~~~~~:USAGE:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; F10 for Playback, F9 for Baking, F8 to kill the script!
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;You Will need to extract these .exes and put them in the same folder as the script-
;if you dont have FFMpeg, FFprobe and FFplay in your PATH Environment Variable already:

;https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffmpeg-4.2.1-win-32.zip
;https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffplay-4.2.1-win-32.zip
;https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v4.2.1/ffprobe-4.2.1-win-32.zip

;======DOCUMENTED SUPPORTED STABLE COMBINATIONS:===================================
;u8 = rgb24 and maybe rgb48le, inside xwd or tiff
;u16le = rgb48le and maybe rgb24, inside tiff
;u32le = rgb48le and rgba64le, inside tiff 
;(maybe try using 3 audio channels and compensate decode sample rate for u32le-
;and decoding with 2 channels, sometimes it works better than not)
;==================================================================================

;PROTIP:
;if you see
;a fair amount of
;random/white noise
;in your output image
;when you zoom in it
;is going to raep
;your mf ears
;okthxbye
;<333

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;DONT TOUCH >:C		
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
GoodFail := "0" ;DONT touch this :b
OneTimeMSG := 1 ;pls DONT touch >:c
roundedBaseDimension := 99999 ;srsly dont ;~;
UniqueFilename := "" ;you will most assuredly regret it o:<

IniRead, FileInput, input.ini, LastInput ;this reads the last used input file
IniDelete,input.ini,LastInput ;this deletes the line in order to be overwritten, to avoid double lines
FileSelectFile,InputFile,,%FileInput% ;this lets you select a file or press enter to select last used file
IniWrite,%InputFile%,input.ini, LastInput ;this rewrites the currently used file to the ini config
FileDelete, %A_ScriptDir%/list.txt ;remove last concat list.txt to avoid conflict with neighboring countries
FileDelete, %A_ScriptDir%/silence.wav ;remove last silence.wav to avoid war with the titans and fairies
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;DONT TOUCH >:C
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;


;===========================================================================================================================================;
;These are settings you can fool around with; be creative! Just be careful with your ears. I have FFplay volume set to 0.3 for a reason lol
;===========================================================================================================================================;
BaseDimension := "1630" ;<~~ ;Dimension to start out with, needs to be biggish; this where the real magic happens right here lemme tell ya!
;===========================================================================================================================================;
SilenceFile := "silence.wav" ;name of generated silence file, dont change if you dont want to. Silence can also help repair unwanted glitches
AddSilence := 0              ;if set to zero obviously it doesnt add silence u dingus, can also change how your glitch ultimately sounds o3o
SilenceDuration := "30.00"   ;duration of silence in seconds, can be very important in helping to make a properly shaped/sized output image
;===========================================================================================================================================;
AudioFormat := "u8"          ;Check "ffmpeg.exe -formats" for more. The usual ones are s8, u8, s16le, s16be, u16le, u16be, u32le, u32be, etc
ChannelCount := "2"          ;Muck about with these as you wish, not sure how much this will change things beyond being mono or stereo
SampleRate := "44100"        ;Very important on how the effects and audio quality will overall sound, maybe more
;===========================================================================================================================================;
ColorSpace := "rgb24"        ;Use rgb24 & rgb4ble or Check "ffmpeg.exe -pix_fmts"; it also tells u the bitcount of them on the side as well
OutputFormat := ".tiff"      ;The output image format that our audio is contained in, use any uncompressed format you wish-
;I use xwd or tiff because ffmpegs bmp encoder seems to encode from bottom up; hence reversing the audio. DM me if you find a better format!~
;===========================================================================================================================================;
BakeFormat := ".flac"        ;The final output audio format you would like to bake/compress your image into after you're all done! (Press F9)
MakeUniqueFilename := 0      ;if set to 1, this will generate uniquely named output files so you can fill up your hard drive with shit lmao!
FFplayFilter := "volume=0.3" ;You can add a lowpass or whatever here too like "lowpass=300,volume=0.3" or anything else you wanna do, or not
;===========================================================================================================================================;
;===========================================================================================================================================;
;===========================================================================================================================================;
;~~~~~~~~~~~~~~~~~~~~~~~~~~> ;This Method Will Only Likely Work With The U8 Format And rgb24 In Its Current State, Be Advised, RIP Your Ears
EnableSecretGlitch := 0    ;Do It I Dare You, you know you wanna try out my terribly written code with math I obviously dont understand lol
ImageBitsPerPixel := "24"    ;Probably shouldnt mess with this unless above is 1; and u use a colorspace other than rgb24 (24 bits per pixel)
SwapDimensions := 0          ;Change this to 1 if you want to swap the dimensions; which creates a different sounding type of glitch >:3
SwapU32 := 0                 ;Dont fuck with this unless your U32 audio is way too loud and pure noise, this fixes it for some reason.
;===========================================================================================================================================;
;           If at any point you find an issue or a new discovery regarding to this process; feel free to reach me at Pandela#0002
;===========================================================================================================================================;
EnableFFmpegLuxification := 0 ;Enables internal FFMpeg Reverse Sonification; i.e audio is processed by internal video filters through a pipe
VideoFilter := "frei0r=pixeliz0r:0.003" ;Edit as you please, correct frei0r usage is "frei0r=glow:20"
;NOTE: incorrect usage would be "frei0r=glow=20", make sure there is a colon after your filters name and each parameter.
oldFFmpeg := A_ScriptDir . "\ffmpeg3.3.2.exe" ;This is the Version of FFMpeg with frei0r & more.
;===========================================================================================================================================;

if (EnableSecretGlitch = 1) && if (EnableFFmpegLuxification = 1) {
	msgbox, Please use one mode at a time.
	return
}
	

;We need to create a symlink for the frei0r folder, 
;because calling ffmpeg in AHk this way makes it look in "/usr/lib/frei0r-1" for some reason...
;This will also only run once.
CurrentDrive := A_ScriptDir
SplitPath,CurrentDrive,,,,,DriveLetter
DriveLetter := DriveLetter . "//"
SymbolicLocation := DriveLetter . "/usr/lib/"

if !FileExist(SymbolicLocation) {
	
	If (!A_IsAdmin){ ;we need the script to run as admin to make changes!
		Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
	}
	
	sleep, 1000
	makeSymLink := "cmd.exe /k cd " . DriveLetter . " && mkdir usr && cd usr && mkdir lib && mklink /D " . chr(0x22) . "/usr/lib/frei0r-1" . chr(0x22) . " " . chr(0x22) . A_ScriptDir . "\frei0r-1" . chr(0x22)
	run, %makeSymLink%
	gosub, FFmpegLuxification
	return
}


SplitPath,InputFile, OutputFilename
SplitPath,InputFile,,,,PaddedOutputName
PaddedOutput := PaddedOutputName . "-Padded.wav"
NoCompression := ""
if (AddSilence = 1) && !FileExist(SilenceFile) {
	
	if !RegExMatch(InputFile, ".wav") { ;if input file is NOT wav then we need to convert it to such for the silence concat to work.
		;msgbox, Converting to wav...	
		NewWav := PaddedOutputName . ".wav"
		MakeWAV := "ffmpeg -i " . chr(0x22) . InputFile . chr(0x22) . " -y " . chr(0x22) . NewWav . chr(0x22)
		runwait, %MakeWAV%
	}	
	
	;if input file is wav then skip encoding.
	if RegExMatch(InputFile, ".wav") {
		NewWav := FileInput
		;msgbox % NewWav
	}
	;Generate Silence and pad it at the end of the input file.
	;msgbox, Generating Silence...
	MakeSilence := "ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=" . SampleRate . " -t " . SilenceDuration . " -y " . SilenceFile
	ConcatTXT := "cmd.exe /c (echo file `'" . NewWav . "`' & echo file `'" . SilenceFile . "`' )>list.txt"
	FinalFile := "cmd.exe /c ffmpeg -safe 0 -f concat -i list.txt -c copy -y " . PaddedOutput
	runwait, %MakeSilence%
	runwait, %ConcatTXT%
	runwait, %FinalFile%
}

if (MakeUniqueFilename = 1) {
	
	Seconds := A_Now
	Seconds -= % SubStr(Seconds, 1, 8), S
	Random, randNum1, 9001, 888888888888
	Random, randNum2, 9001, 696969696969
	Minute := A_Min
	Day := A_YDay
	Week := A_YWeek
	Year := A_YEAR
	UniqueFilename := randNum1 . Minute . Day . randNum2 . Week . Year . randNum1 . Seconds . randNum2
	
	str2hex(str)
	{
		loop, parse, str
			hex .= Format("{:x}", Asc(A_LoopField))	
		return hex
	}
	HexName := str2hex(UniqueFilename)
}

if (EnableFFmpegLuxification = 1) {
	gosub, FFmpegLuxification
	return
}

if (EnableSecretGlitch = 1) {
	gosub, ItsNotABugItsAFeature
	return
}

;if no silence is generated then carry on as normal.
if (AddSilence = 0) {
	PaddedOutput := InputFile
}

;if output image format is tiff we need this flag set!
if RegExMatch(OutputFormat,".tiff") {
	NoCompression := " -compression_algo raw "
}


;This is where the first iteration of image is generated.
loop, {
	FinalFile := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . AudioFormat . "_" . ColorSpace . "_" . BaseDimension . "x" . BaseDimension . "_" . UniqueFilename . OutputFormat	
	gibaudio := "cmd.exe /k ffmpeg -i " . chr(0x22) . PaddedOutput . chr(0x22) . " -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | ffmpeg -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " -i - " . NoCompression . chr(0x22) . FinalFile . chr(0x22) . " -y"
	GenerateFile := ComObjCreate("WScript.Shell").Exec(gibaudio).StdErr.ReadAll() ;open ffmpeg with a shell and read stderr/console output.
	List.Visible := false
	clipboard := StrReplace(gibaudio,"cmd.exe /k ","")
	CheckConsole := SubStr(GenerateFile, InStr(GenerateFile, "[rawvideo @") + 23) ;cut string down.
	
	;USEFUL FOR DEBUGGING!!!
	;msgbox % CheckConsole
	;clipboard := GenerateFile
	;USEFUL FOR DEBUGGING!!!
	
	;When this is triggered thats a good thing, go with a higher value. 
	;Otherwise you will have incomplete output and likely "unwanted" glitches when image filters are applied.
	if RegExMatch(CheckConsole, "frame=    1") && (GoodFail = 0) {
		msgbox, The image was generated but this completed too soon,`ntry a slightly higher number!`n`nOr else you will suffer undesirable artifacts and consequnces
		FileDelete, %A_ScriptDir%/list.txt ;remove last concat list.txt to avoid conflict
		FileDelete, %A_ScriptDir%/silence.wav ;remove last silence.wav to avoid conflict
		FileDelete, %A_ScriptDir%/%FinalFile% ;Remove the undesired output to save on diskspace
		FileDelete, %A_ScriptDir%/%PaddedOutput% ;clean up extra files
		FileDelete, %A_ScriptDir%/%NewWav% ;clean up extra files; fuck you
		ExitApp ;break le loop
	}
	
	
	;This will keep subtracting from BaseDimension until we get an output file :3
	if RegExMatch(CheckConsole, "frame=    0") {
		
		if (OneTimeMSG = 1) {
			msgbox, No image was generated, but in this case thats good!`nSit tight while we messily get the correct dimensions :3c
			;mynamepandelalol					
			OneTimeMSG := 0
		}
		
		;subtract 1 from BaseDimension
		BaseDimension := (BaseDimension - 1)
		GoodFail := 1
		continue ;keep the loop goin
	}
	
	;if ffmpeg console output has the text "frame=    1"
	;then we know we have a proper file!
	if RegExMatch(CheckConsole, "frame=    1") && (GoodFail = 1) {
		msgbox, image generated!`nThe dimensions were %BaseDimension%x%BaseDimension%`nAlso check your clipboard :>`n`n(Before and After you close this msg)
		Clipboard := StrReplace(gibaudio,"cmd.exe /k ","")
		
		;msgbox, rounding down to nearest zero...		
		
		;if the Base Dimensions are less than 1000 then it seems we need to round it down to the nearest hundred; to avoid unwanted clicks in audio
		if (BaseDimension < 1000) {
			lemath := 10**(StrLen(BaseDimension)-1) ;Count string length; ** is the same as saying "exponents" and the -1 at the end makes the string always one digit less, for now.
			roundedBaseDimension := Floor(BaseDimension / lemath) * lemath
			
		}
		
		;if the Base Dimensions are more than 1000 then it seems we are able to properly encode Audio to image by rounding down to the nearest zero.
		if (BaseDimension > 1000) {
			lemath := 10**(StrLen(BaseDimension)-3) ;Count string length; ** is the same as saying "exponents" and the -1 at the end makes the string always one digit less, for now.
			roundedBaseDimension := Floor(BaseDimension / lemath) * lemath
		}
		
		;;;msgbox % roundedBaseDimension
		FinalRoundedFile := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . AudioFormat . "_" . ColorSpace . "_" . roundedBaseDimension . "x" . roundedBaseDimension . "_" . UniqueFilename . OutputFormat
		
		;This is where the final image is generated.
		gibaudio := "cmd.exe /k ffmpeg -i " . chr(0x22) . PaddedOutput . chr(0x22) . " -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | ffmpeg -f rawvideo -pix_fmt " . ColorSpace . " -s " . roundedBaseDimension . "x" . roundedBaseDimension . " -i - " . NoCompression . chr(0x22) . FinalRoundedFile . chr(0x22) . " -y"
		GenerateFile := ComObjCreate("WScript.Shell").Exec(gibaudio).StdErr.ReadAll() ;open ffmpeg with a shell and read stderr/console output
		List.Visible := false
		
		clipboard := StrReplace(gibaudio,"cmd.exe /k ","")
		break ;stop the loop
	}
	
	if RegExMatch(CheckConsole, "frame=    2",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    3",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    4",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    5",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    6",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    7",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    8",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    9",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    10",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    11",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    12",FrameCountInfo) or RegExMatch(CheckConsole, "frame=    13",FrameCountInfo) {
		msgbox, hmmm... There are too many output frames.`nIn this case: %FrameCountInfo%`n`nConsider this a failiure and use a bigger value
		FileDelete, %A_ScriptDir%/list.txt ;remove last concat list.txt to avoid conflict
		FileDelete, %A_ScriptDir%/silence.wav ;remove last silence.wav to avoid conflict
		FileDelete, %A_ScriptDir%/%FinalFile% ;Remove the undesired output to save on diskspace
		FileDelete, %A_ScriptDir%/%PaddedOutput% ;clean up extra files or gtfo
		FileDelete, %A_ScriptDir%/%NewWav% ;clean up extra files for fucks sake
		;Clipboard := gibaudio
		;break ;stop the loop
		sleep, 30
		exitapp
	}
	
}

FileDelete, %A_ScriptDir%/list.txt ;remove last concat list.txt to avoid conflict
FileDelete, %A_ScriptDir%/silence.wav ;remove last silence.wav to avoid conflict
FileDelete, %A_ScriptDir%/%PaddedOutput% ;clean up extra files
FileDelete, %A_ScriptDir%/%NewWav% ;clean up extra files
SoundBeep,600,60 ;wao its done :pog:
SoundBeep,800,60 ;wao its really really done :pinkiepog:
return



F10:: ;Listen To Your Image!
FFformat := AudioFormat
if RegExMatch(AudioFormat,"u32be") && (SwapU32 = 1) {
	FFformat := "u32le"
}

Playback := "cmd.exe /c ffplay -loop 0 -f " . FFformat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i " . chr(0x22) . FinalRoundedFile . chr(0x22) . " -af " . FFplayFilter
if (EnableSecretGlitch = 1) {
	
	Playback := "cmd.exe /c ffplay -loop 0 -f " . FFformat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i " . chr(0x22) . OddlyShapedImageName . chr(0x22) . " -af " . FFplayFilter
}

if (EnableFFmpegLuxification = 1) {
	
	Playback := "cmd.exe /c " . oldFFmpeg . " -i " . chr(0x22) . InputFile . chr(0x22) . " -vn -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | " . oldFFmpeg . " -loglevel debug -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " -i - -vf " . VideoFilter . " -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " - | ffplay -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -"
}

;msgbox % Playback
run, %Playback%
clipboard := StrReplace(Playback,"cmd.exe /c ","")
return


F9:: ;Bake Your Image Back Into Sound!
FinalBakedFilename := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . FFformat . "_" . ColorSpace . "_" . roundedBaseDimension . "x" . roundedBaseDimension . "_" . UniqueFilename . BakeFormat
FFformat := AudioFormat
if (EnableSecretGlitch = 1) {
	FinalRoundedFile := OddlyShapedImageName
	FinalBakedFilename := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . FFformat . "_" . ColorSpace . "_" . width . "x" . height . "_" . UniqueFilename . BakeFormat	
}

if (EnableFFmpegLuxification = 1) {
	VideoFilterInfo := RegExReplace(VideoFilter,":","_")
	FinalBakedFilename := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . FFformat . "_" . ColorSpace . "_" . BaseDimension . "x" . BaseDimension . "_" . VideoFilterInfo . "_" . UniqueFilename . BakeFormat	
	Image2Audio := "cmd.exe /c " . oldFFmpeg . " -i " . chr(0x22) . InputFile . chr(0x22) . " -vn -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | " . oldFFmpeg . " -loglevel debug -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " -i - -vf " . VideoFilter . " -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " - | ffmpeg -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i - " . FinalBakedFilename . " -y"
	Run, %Image2Audio%
	Return
}

if RegExMatch(AudioFormat,"u32be") && (SwapU32 = 1) {
	FFformat := "u32le"
}

sleep, 20
Image2Audio := "ffmpeg -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i " . chr(0x22) . FinalRoundedFile . chr(0x22) . " -af anull " . chr(0x22) . FinalBakedFilename . chr(0x22)
Run, %ComSpec%
WinWaitActive, ahk_exe cmd.exe
Send, %Image2Audio% {Enter}
Return


F8:: ;GET THAT SHIT OUTTA HERE!
ExitApp













;My old unfinished code to almost do the correct math to accurately achieve this process
;At the moment is a unique approch that yields different results than the above
;For some reason a width or height of 1000 just works, I'm currently missing the math in order to calculate the height.
;So far I can only calculate the width, and sadly dividing that by two doesn't work either...
;If you have any ideas on how I could achieve this please don't hesitate contacting me!~
;Hell I'll even reward you for your efforts, swear on me mum.
ItsNotABugItsAFeature:
ResInput := chr(0x22) . InputFile . chr(0x22)
if (AddSilence = 1) {
	ResInput := chr(0x22) . PaddedOutput . chr(0x22)
	msgbox % ResInput
	
}

If RegExMatch(ResInput,"(m4a|flac|aic|ogg|wav|mp2|mp3|mp4)") {
	
	CreateTemplateFile := ComSpec . " /c ffmpeg  -i " ResInput . " -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -y itsacompression.party"
	;msgbox % CreateTemplateFile
	runwait, %CreateTemplateFile%
	
	;Get the bitrate of the newly encoded uncompressed file.
	bitratepls := "ffprobe -show_entries format=bit_rate -v quiet -of csv=s=x:p=0 -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i itsacompression.party"
	Bitrate := ComObjCreate("WScript.Shell").Exec(bitratepls).StdOut.ReadAll() ;Execute ffprobe and save stdout to variable!
	;msgbox % Bitrate
	
	StringReplace, Bitrate, Bitrate, `r`n, %A_Space%, All ;Remove linebreak from bitrate
	transform, Bitrate, Deref, %Bitrate%
	StringTrimRight, Bitrate2, Bitrate, 4 ; Cut Bitrate length to what ffmpeg normally displays it as because im dumb ***honestly dont remember what i was doing here but it mustve been important***
	
	
	Durationz := "ffprobe -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -i itsacompression.party -show_entries format=duration -v quiet -of csv=s=x:p=0"
	GetDurationPls := ComObjCreate("WScript.Shell").Exec(Durationz).StdOut.ReadAll() ;Execute ffprobe and save stdout to variable!
	;msgbox % GetDurationpls
	
	sleep, 100
	StringReplace, GetDurationPls, GetDurationPls, `r`n, %A_Space%, All ;Remove linebreak from clipboard
	Duration := GetDurationPls
	
	
	;================================================================================================================================================================;
	;This is where the math happens
	;================================================================================================================================================================;
	Duration := floor(Duration) ;Convert duration to integer
	size := (Duration*Bitrate2) ;Multiply Duration by bitrate
	width := (size/ImageBitsPerPixel) ;Divide width by bits per pixel, bgr24 in this case
	width := floor(width) ;Convert float to integer
	
	OriginalWidth := width ;;Save Original width value
     ;StringLen, Length, width ;;old method
     ;Length := (Length -2) ;;Subtract two from the width strings total length ; old method
	lemath := 10**(StrLen(width)-1) ;Count string length; ** is the same as saying "exponents" and the -1 at the end makes the string always one digit less, for now.
	width := Floor(width / lemath) * lemath ;iirc this evens the output dimension to all zeros or whatever :b tell me if im wrong bls
	width1 := (width * 32)
	width2 := (width1 / 2)
	
	height = 1000 ;dont ask why this works but ayylmfao we always need a height of 1000 for this method to work, in its current state
	;================================================================================================================================================================;
	;This is where the math ends
	;================================================================================================================================================================;
	
	
	msgbox, Kind of Converted Audio To Resolution -s %width%x%height%`nOriginal Width Was %OriginalWidth% Before Being Rounded Down
     ;global swappedRes := -s %width%x%height% ; huehuehue
     ;GuiControl,, GlobalRes, -s %width%x%height%
     ;global SEX := clipboard
	;msgbox, `nBitrate Is Now: %Bitrate2%`nOriginally: %Bitrate%
	
	
	;3
	if (SwapDimensions = 1) {
		width2 := width ;store temp value
		height2 := height ;store temp value
		
		width := height2 ;swap width for temp value
		height := width2 ;swap height for temp value
		
		width2 := "" ;clear temp value
		height2 := "" ;clear temp value
	}
	
	
	
	;if output image format is tiff we need this flag set!
	if RegExMatch(OutputFormat,".tiff") {
		NoCompression := " -compression_algo raw "
	}
	
	
	OddlyShapedImageName := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . AudioFormat . "_" . ColorSpace . "_" . width . "x" . height . "_" . UniqueFilename . OutputFormat
	OddlyShapedImage := "cmd.exe /c ffmpeg  -i " . ResInput . " -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | ffmpeg -f rawvideo -pix_fmt " . ColorSpace . " -s " . width . "x" . height . " -i - " . NoCompression . OddlyShapedImageName . " -y"
	
	OddlyShapedImageNameUnrounded := OutputFilename . "_" . SampleRate . "hz_" . ChannelCount . "-ch_" . AudioFormat . "_" . ColorSpace . "_" . OriginalWidth . "x" . height . "_" . UniqueFilename . OutputFormat
	OddlyShapedImageUnrounded := "cmd.exe /c ffmpeg  -i " . ResInput . " -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | ffmpeg -f rawvideo -pix_fmt " . ColorSpace . " -s " . OriginalWidth . "x" . height . " -i - " . NoCompression . OddlyShapedImageNameUnrounded . " -y"
	
	runwait, %OddlyShapedImage%
	runwait, %OddlyShapedImageUnrounded%
	clipboard := StrReplace(OddlyShapedImage,"cmd.exe /c ","") ;copy dat shit to clip
	
	FileDelete, itsacompression.party
	FileDelete, %A_ScriptDir%/list.txt ;remove last concat list.txt to avoid conflict
	FileDelete, %A_ScriptDir%/silence.wav ;remove last silence.wav to avoid conflict
	FileDelete, %A_ScriptDir%/%PaddedOutput% ;clean up extra files
	FileDelete, %A_ScriptDir%/%NewWav% ;clean up extra files
	
	SoundBeep,600,60 ;i think its done lol
	SoundBeep,800,60 ;could it be? Its done?
	return
}
return




;Internal FFMpeg Reverse Sonification!
FFmpegLuxification:
gibaudio := "cmd.exe /c " . oldFFmpeg . " -i " . chr(0x22) . InputFile . chr(0x22) . " -vn -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " - | " . oldFFmpeg . " -loglevel debug -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " -i - -vf " . VideoFilter . " -f rawvideo -pix_fmt " . ColorSpace . " -s " . BaseDimension . "x" . BaseDimension . " - | ffplay -f " . AudioFormat . " -ac " . ChannelCount . " -ar " . SampleRate . " -"
run %gibaudio%
clipboard := StrReplace(gibaudio,"cmd.exe /c ","")
Return
