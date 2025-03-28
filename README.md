# Meditation

<img width=200 src="media/logo-wide.png"><img>
<!-- <img height=64 src="media/icon-playstore-512px.png"><img> -->

*This is a meditation timer. Minimalistic, reliable, and truly elegant.*

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
    alt="Get it on F-Droid"
    height="80">](https://f-droid.org/packages/com.nyxkn.meditation/)
     
[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
    alt="Get it on Google Play"
    height="80">](https://play.google.com/store/apps/details?id=com.nyxkn.meditation)

Or download the APK directly from GitHub:

- **[Latest release](https://github.com/nyxkn/meditation/releases/latest)**

## Features

![Shield: GitHub version](https://img.shields.io/github/v/release/nyxkn/meditation?style=for-the-badge&logo=github)
![Shield: F-droid version](https://img.shields.io/f-droid/v/com.nyxkn.meditation?style=for-the-badge&logo=fdroid)

* Simple, elegant, and intuitive
* No distractions - only the essential features
* Beautiful assortment of bell and gong sounds
* Custom volume adjustment of the bell sounds
* Reliable countdown timer
* Pre-meditation delay
* Intermediate meditation intervals
* Free and open-source software

## Screenshots

<a href="media/screenshots/main.png?raw=true"><img width=180 src="media/screenshots/main.png"></a>
&nbsp;
<a href="media/screenshots/time-selection.png?raw=true"><img width=180 src="media/screenshots/time-selection.png"></a>
&nbsp;
<a href="media/screenshots/settings.png?raw=true"><img width=180 src="media/screenshots/settings.png"></a>
&nbsp;
<a href="media/screenshots/settings-2.png?raw=true"><img width=180 src="media/screenshots/settings-2.png"></a>

## Description

<i>Meditation</i> is a truly minimalistic countdown timer for meditation, with a clean user interface and no clutter. The minimalism of the app embodies meditation's actual purpose.

A notable feature of the app is the ability to customize the volume of the notification bells independently of system volume. This allows you to set a predefined volume so that the sounds will reliably play at the same loudness every time. No more mid-meditation worrying that you remembered to turn the volume up!

Another important feature is for the timer to be as reliable as possible, to ensure an accurate meditation time and prompt ending sound notification.
This is achieved by starting a foreground service and disabling battery optimization.

Reliability is of extreme importance to a meditation tool in order to eliminate all possible worries about the timer not behaving correctly. Just press the button and start!

## Donations

If you find this project helpful and you feel like it, throw me some coins!

And drop a [star](stargazers) on this repo :)

[![Buy me a coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/nyxkn)

[![Liberapay](https://img.shields.io/badge/donate-liberapay-F6C915?style=for-the-badge&logo=liberapay&logoColor=)](https://liberapay.com/nyxkn)

[![Support me on ko-fi](https://img.shields.io/badge/support%20me%20on%20ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=black)](https://ko-fi.com/nyxkn)

[![Paypal](https://img.shields.io/badge/donate-paypal-00457C?style=for-the-badge&logo=paypal&logoColor=)](https://paypal.me/nicolasiagri)

Bitcoin: bc1qfu5gk78898zdcxw372unmwua0yd5luf3z60sgq

## Technical notes

An important feature to implement was to have the volume of the notification bells be consistent and reliable.
In other apps, the volume is tied to the system volume, implemented either as using the system volume setting directly, or as a modifier thereof.
Both approaches are flawed and will lead to inconsistent volumes if the system volume changes or if you had forgotten to set it to the desired level before starting the timer.
With my approach the app makes use of a configurable absolute value, so that the sounds play consistently at the same volume no matter what.

Another issue to solve was the reliability of the timer timeout event, making sure it happens at exactly the right time.
For whatever reason, this is a ridiculously complex problem on mobile devices. There are continuous "improvements" to attempt to extend battery life, that make it really hard to ensure that a time-critical task happens at the right time.
This app will make use of all possible tricks to ensure it is reliable. What I settled on was a combination of a foreground service and disabling battery optimization. This allows notifications to be sent reliably at the correct time. If that still doesn't work, you also have the option of keeping the screen on through wakelock.

## Credits

### Audio files

Here's a listing of the original audio files that each asset was derived from.
They were all modified to improve cohesion.

- bell_burma: <https://freesound.org/people/LozKaye/sounds/94024/> (CC0)
- bell_indian: <https://soundbible.com/1690-Indian-Bell.html> (CC Sampling Plus 1.0)
- bell_meditation: <https://freesound.org/people/fauxpress/sounds/42095/> (CC0)
- bell_singing: <https://freesound.org/people/ryancacophony/sounds/202017/> (CC0)
- bowl_singing_big: <https://freesound.org/people/Garuda1982/sounds/116315/> (CC0)
- bowl_singing: <https://freesound.org/people/juskiddink/sounds/122647/> (CC-BY 3.0)
- gong_bodhi: <https://github.com/yuttadhammo/BodhiTimer> (origin unclear)
- gong_generated: <https://freesound.org/people/nkuitse/sounds/18654/> (CC0)
- gong_watts: <https://github.com/yuttadhammo/BodhiTimer> (origin unclear; possibly from the "Alan Watts Guided Meditation" audio)

### Other

- [Enso.svg](https://commons.wikimedia.org/wiki/File:Enso.svg) (CC0): used in the making of the app icons.

## License

### Source code

All source code is licensed under the [GPL-3.0-only License](https://spdx.org/licenses/GPL-3.0-only.html).

> This program is [free software](https://www.gnu.org/philosophy/free-sw.html): you can redistribute it and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html) as published by the Free Software Foundation, version 3.

### Assets

All assets (images and audio files) are licensed under the [CC-BY-SA 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/).

This includes everything in the *assets* and *media* folders and in *android/app/src/main/res*.

### Third-party

This project is developed using the [Flutter framework](https://flutter.dev/), which is licensed under the [BSD 3-Clause License](https://github.com/flutter/flutter/blob/master/LICENSE).

Additional licensing information on all of the Flutter modules that are being used can be found in the in-app *About* screen.
