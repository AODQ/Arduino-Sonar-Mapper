# Arduino-Sonar-Mapper

A very silly project of mapping sonar readings from an HC-SR04 to 3D geometry. It serves no practical purpose.
The geometry-mapping component uses DLang, communicating to the arduino over serial-port, and OpenGL to render.
It uses my Arduino Utility library along with my Parallel Sonar library, which allows sonars to send and receive
sound waves in parallel. Of course, their field-of-view can't intersect otherwise they might collect each other's results.

Video of it in action: https://www.youtube.com/watch?v=4PG0_yIogY4

![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0-Rendering.png?raw=true)

Rendered from this scene (sonars generally can't detect surfaces such as sponges):
![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0.jpg?raw=true)

The difficulty of course is that sonar's have a wide FOV and are very inaccurrate.
I'm currently looking into what degree I can improve the readings by moving the sonar's location (thus being able to, along with collecting more data, override original inaccurrate sonar readings).

# HOW TO USE
The most difficult part is to build a sonar model, its origin centered on the sonar itself, in other words, the rotation of the sonar should not alter its position.

Then install the two libraries, my Utility and Parallel Sonar libraries, and then upload the source code in main.epp to your arduino. It should be noted, I've only used this on an Arduino Nano so you might have to configure it yourself. The Trig and Echo pins are 4 and 2, while the servo rotation pins are 11 and 12 I believe. You might have to configre it a bit. But once that's done, the rest is simple, as all that's left is to run the DLang software (install DUB & DMD, then simply `dub` in the `visualizer` repository will build & run it), and the visualizer will handle the rest.
