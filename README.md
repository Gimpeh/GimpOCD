GimpOCD - Overseeing, Controlling, Directing
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
