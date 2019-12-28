# single image

Here is contribution to have BIOS included in the HD image.
So only the HDD image has to be written at the start of SD card.
BIOS doesn't have to be written to the last 8K of the SD card.

emard:

loading 8K bios from beginning of partition would make
everything a single image just to dump at beginning of SD card.
My repository for ULX3S is here it compiles and boots.

fanoush:

you have no issue tracker there I would just post those two files as
attachment or just the diff there if you don't mind, no time for PR now
or I will just post it as a text to gist, now i see even the mem file is
text - here: diff and mem so I see it first tries from end of card like
before and then tries to  search for bios signature from sector 1,
already forgot how I did it :-)

it can start anywhere after MBR up to sector 63 in case there is a need
to have some other stuff hidden there too, I think this space was used at
DOS days for IDE LBA translation code or maybe stacker - disk compression etc.
already forgot where it goes but I think the mem file should go to 
[Cache_bootload.mem](https://github.com/emard/Next186/blob/master/proj/ulx3s/Cache_bootload.mem)
or is part of it. I remember setting the path to it in some Diamond
dialog for the cache but not sure if there was more to it.
