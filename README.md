# firebase_test
test lab troll

drop the sounds folder in the C drive and add the `troll.vbs` to startups folder (can be accessed by doing win+r -> `shell:startups`)

linked to firebase db (create your own firebase db with the appropriate fields and use it in the script), modify the `index.html` for the same

Runs on startup, open the html in the browser and use it to trigger the sound, you may add your own sounds, add more triggers, etc...
For every trigger the volume up button is triggered 50 times which makes sure the volume is at max before playing the sound, this combined with the frequency of fetching json from the firebase db causes delay in the sound playing after you press the trigger button on the html. You may modify the script as per your needs...

Will be improved later.
