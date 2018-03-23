# Arduino-Sonar-Mapper

A very silly project of mapping sonar readings from an HC-SR04 to 3D geometry. It serves no practical purpose.
The geometry-mapping component uses DLang, communicating to the arduino over serial-port, and OpenGL to render.

Video of it in action: https://www.youtube.com/watch?v=4PG0_yIogY4

![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0-Rendering.png?raw=true)
Rendered from this scene (sonars generally can't detect surfaces such as sponges):
![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0.jpg?raw=true)

The difficulty of course is that sonar's have a wide field-of-view and are very inaccurrate.
I'm currently looking into what degree I can improve the readings by moving the sonar's location (thus being able to, along with collecting more data, override original inaccurrate sonar readings).
