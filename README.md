GimpOCD - Overseeing, Controlling, Directing
-----------------

This is still under HEAVY development. A lot of features are missing and all that. 
Expect Bugs. You have been warned!

Real installers will be available on release to make parts of installing this easy, and do things like set autorun, choose which modules are available in the UI, and more.
Not right now however.

-----------------

Made for the Gregtech New Horizons modpack (minecraft)

Overview
-----------------

This is a UI for the Opencomputers Glass

Features;

Battery Widget - for monitoring power metrics

Item Monitoring - Interface with an ME system and allows selecting Items to keep track of (display on the HUD coming soon)

Level Maintaining - Like an AE level maintainer but with much more configuration available

Gregtech Machine/Multi monitoring/controlling - Displays if machines are disabled/enabled, if they are running, and allows turning them on/off. (Mostly back on due to power loss or something stupid =])

Highlighting Disabled machines - Creates Red Dots at Disabled machines' locations if enabled.

Highlighting Machines Requiring Maintenance - Same as above

More features coming soon!

Setup
----------------

The current required systems are an opencomputers server and a supporting opencomputers computer (referred to as subsystem).

-----------

Recommended for the server;

Creative APU

4 Memory(Tier 3.5) OR BETTER

I'd be surprised if it required anything more than a Tier 1 HDD, unless you try to capture the output. Then it will easily fill a RAID array with 3 tier 3's

A Wireless Card

An Internet Card

---------------

Recommended for the subsystem;

Tier 3 APU

1 Memory(Tier 3.5) will do it. Almost certainly requires less with 1 battery connected.. Almost certainly requires more with 100 batteries connected

A Hard Drive

A wireless card

Optionally, add a redstone component and configure the battery monitoring program for generator control

Optionally an internet card for the downloader

---------------

The subsystem needs to be connected to whatever battery (batteries) you wish to monitor. Any batteries, in any combination, technically in almost any amount.

Optionally connect its redstone component to a generator (containing the relevant cover) and configure the battery_monitor.lua file to have it control generators. This is not recommended however.. other ways are always more reliable than any opencomputers system.

![image](https://github.com/user-attachments/assets/ad2236cf-cdde-46f9-95fc-33cc567d678a)

change to

![image](https://github.com/user-attachments/assets/bf45b0f7-1756-476c-8cd2-38dc2b04b2b3)

setting the number to whatever number required.. almost certainly more than the number in the picture =].

```
wget https://raw.githubusercontent.com/Gimpeh/GimpOCD/semi-stable/Supporting%20Systems/Battery_Monitor.lua battery_monitor.lua
```

run it from the directory you downloaded it from with `battery_monitor.lua` from the command line

-----------------

The Server requires the following additional components;

1 ME Interface that is connected to the system to be monitored

1 Glasses Controller

probably 2 dozen opencomputers capacitors (Or you could just edit the openglasses config to make it not consume a buttload of energy)

------------------

The server also requires you to create a groups.config file. Eventually systems for creating it will be included and run during install.

![image](https://github.com/user-attachments/assets/87a85765-c81f-4723-8ff8-833f2d497198)

The system in the image has 2 groups specified in its groups.config file

Active1 with 26 machines and Distillation with 17 machines.

That means that 26 machines literal coordinate location in the world fall within the range specified under Active1's entry.


First, create the file
```
edit /home/programData/groups.config
```

ChatGPT should be able to help you create the file if this part is confusing to you. Just paste the following into a chat with it;
```
This file is for specifying coordinate ranges. The start coordinates should always be the lower of the 2 values. 
The file should contain a lua array structured as follows (with a prepending return statement);

return {
  [1] = {
    name="<group name>",
    start={
      x=<The starting x coordinate for the groups coordinate range>,
      y=<The starting y coordinate for the groups coordinate range>,
      z=<The starting z coordinate for the groups coordinate range>
    },
    ending={
      x=<The ending x coordinate for the groups coordinate range>,
      y=<The ending y coordinate for the groups coordinate range>,
      z=<The ending z coordinate for the groups coordinate range>
    }
  }
}

So for example;

return {
  [1] = {
    name="All",
    start={
      x=-100000000,
      y=0,
      z=-100000000
    },
    ending={
      x=1000000000,
      y=1000,
      z=1000000000
    }
  },
  [2] = {
    name="none",
    start={
      x=0,
      y=0,
      z=0
    },
    ending={
      x=0,
      y=0,
      z=0
    }
  }
}
```
The example will work, it will create 2 groups.

All will almost certainly contain all of your connected gregtech machines (if not then MAD props)

none will not contain any and is provided merely to demonstrate adding another entry.

----------------------

after that install GimpOCD on the server;

```
wget https://raw.githubusercontent.com/Gimpeh/GimpOCD/semi-stable/very_basic_terrible_installer.lua d && d
```

you can now run it with the following command from any directory;

```
GimpOCD.exe
```

and thats should be it...
other than setting the hotkey for opening the overlay.

If the battery widget disappears after setting its location and closing the overlay, do not despair.

Just open and close the overlay and it should be resolved. And it shouldnt happen again.

The Program
---------------------------------

Seeing how the 'show help' config option isnt operational yet, This section will cover how to use the UI.

First, most of the tabs have little square buttons with little 'arrows'

![image](https://github.com/user-attachments/assets/c8fc3220-0d97-4674-b729-cd1779c7ca09)

These are for scrolling through the displayed content.

------------------------------

The first tab on opening the overlay;
![image](https://github.com/user-attachments/assets/dc412c48-0bd5-4365-890e-d9ab6ffa6355)

The boxes for the different groups are white if all enabled, purple if some are disabled, red if all are disabled, and yellow if processing user clicks.

Clicking the purple buttons at the top switches tabs.

Left clicking on one of the machine groups (Active1 or Distillation in the image) turns all machines contained within on or off.
On if none are running, off if any are running.

Double clicking might not cycle then off then back on if you click too fast, but there should be enough of a delay that you can cycle them all on in the case of machines with controlling covers.

Right clicking on one of the machine groups pull up a sub menu displaying individual machines.

![image](https://github.com/user-attachments/assets/553925ff-cd33-472f-b5ea-daf0c562e330)

as you can see, I still definately need to do something about long machine names.. and I will.

Red means disabled, white means enabled.

Left clicking a machine cycles its state (disable/enabled)

Right clicking sets a beacon (teal dot) to the machine in the world. -- although right this second, it will be to the wrong location unless you change the values for gimp_globals.glasses_controller_coords to the coords of your glasses controller. (this will eventually be configurable in the overlay as well as obtained from users during the installation process. But that is not included just yet.

Middle Mouse Button Allows you to set the machine name (for the overlay only). MAKE SURE TO PRESS ENTER AFTER ITS TYPED IN!! I don't actually know what will happen if you forget to do so.

The cyan button in the top right allows you to go back to the Machine Groups page. (Yes it will be labeled in the future)

----------------------------

The storage tab is for your connected ME systems storage.

![image](https://github.com/user-attachments/assets/0d917b44-8856-4120-bc63-8a214cb1a4ad)

Typing while in the tab will usually input text into the search bar. Pressing after entering text will change the items displayed from your ME system. (the big box containing items on the left)

At this time, it only searches exact case sensitive strings. (so sto wont show anything, stone won't show anything, but Stone will show stone) REAL search functionality is incoming soon.

This doubles up as a fluid monitor (search `drop of Nitrogen Gas` for example)

Clicking an item in the ME box (left box) adds it to the bottom box, which is merely for easy monitoring. Soon items in the bottom box will probably be able to be displayed on the HUD in addition to within the overlay. Right click or middle click an item in the bottom box to get rid of it.

The white boxes (they actually are only white at first, this will be fixed) by the green and red boxes changes what section items are added to. When they are white or yellow, they aren't active. While they are green, clicking items in the main box adds the item to the active section.

The red section isnt actually used currently. It was going to be a reverse level maintainer (void items after amount reached).. but after testing, it would require a fair bit from users to scalable. And would take up too much space and be ugly and all that. So I'm probably not going to add in that functionality. It will probably be converted to the Display on HUD section.

The green box (the top right) is for level maintaining the selected object. THESE WONT LEVEL MAINTAIN UNTIL CONFIGURED IN THE OPTIONS TAB, which we will cover later.

At the time of this writing (Im fixing this as soon as I'm done here and pushing the fix to this branch) removing an item from the level maintainer (with a middle click) temporarily breaks the level maintainer display (but does remove the item from it), which can be fixed by switching to a different tab and back again... dont do the machines tab though. (clicking before it is loaded causes its background box to persist, which can only be fixed by restarting the entire program. Also a thing I intend to fix VERY shortly) #bugsIjustFound

![image](https://github.com/user-attachments/assets/42de3535-5704-4129-aed1-783db4694c4e)

Left clicking on batch lets you set the batch (number of crafting recipes to initiate at a time) make sure to press enter when finished setting it. (makes keyboard input go to the batch box instead of the search bar) Left click on amount lets you set the amount in the exact same way. Which is the amount to keep in stock.

In the future, there will be a way to set the main item display's items to only those that are craftable in the system. That is not currently the case however.

-------------------------------------------------------------

The last functioning tab, options allows you to set various setting, as well as allowing you to reconfigure where the battery widget (and when they exist other HUD display item) are located.

Before you get excited. The show help option doesnt actually do anything yet.

![image](https://github.com/user-attachments/assets/1de935d3-761e-46ee-bee6-28e32230854c)

This is what the page looks like when it is first initialized.

NOTE THE SAVE BUTTON!

While the UI does try to save values at times other than when the save button is clicked, it is currently not the most reliable way of saving the data. The save button is.

Also, the save button actually updates (and starts) the level maintainer as well as actually enabling the settings in The general configurations (Hight disabled, etc) Eventually this will be fixed... but that one might be a bit.

