# Arduino-Sonar-Mapper

A very silly project of mapping sonar readings from an HC-SR04 to 3D geometry.
It serves no practical purpose.
In general, it works by calculating distance over sonar and sending the
distance over serial-port to the machine. The geometry-mapping component uses
DLang, by receiving the distance results and construct a sparse voxel octree of
the results. From this the results are all rendered using OpenGL by instanced
voxels that fill the octree.

Video of it in action [here](https://www.youtube.com/watch?v=6Xcm2GSGwrw)
![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/updated-shader.png?raw=true)

It uses my Arduino Utility library along with my Parallel Sonar library, which
allows sonars to send and receive sound waves in parallel. However of course,
the latter isn't fully utilized in this project.

![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0-Rendering.png?raw=true)

Rendered from this scene (sonars generally can't detect surfaces such as sponges):
![](https://github.com/AODQ/Arduino-Sonar-Mapper/blob/master/screenshots/Scene0.jpg?raw=true)

The difficulty of course is that sonar's have a wide FOV and are very inaccurrate.
I've thought of different ways to which one can improve the readings, but this
mostly requires the location of the sonar to change in order to get a different
set of readings. This hardware runs out of the scope of my project, however
there are a few interesting methods you could improve on top of this given such
hardware (a mobile sonar whose rotational origin is at its center):

] Raymarch through the SVO to remove voxels that are less than the distance of
    which you are located in. A prototype of such a function is already
    included in the source code for the SVO. This would, over time, give better
    results as erroneous voxels are removed, however the reverse is also true.
    
] If an octree node contains >N children, construct a node for that parent, in
    a recursive manner. The locations of the children could also modify the
      model/angle of which the voxel should be. Of course the accuracy of such
      thing is suspicious at best, so the results of such an implementation would
      be interesting.

] Isosurface reconstruction is an interesting idea, however this requires a very
    large number of sampling from the sonar; knowing the point at which an
    isosurface can be reconstructed in a specific region is interesting.
    However, afterwards, just viewing this like you would any other model from
    which you could pick discrete points, such as scalar or signed distance
    fields. You could extract a triangular mesh using marching cubes, dual
    contouring, etc.

# HOW TO USE
The most difficult part is to build a sonar model, its origin centered on the
sonar itself, in other words, the rotation of the sonar should not alter its
position.

Then install the two libraries, my Utility and Parallel Sonar libraries, and
then upload the source code in main.epp to your arduino. It should be noted,
I've only used this on an Arduino Nano so you might have to configure it
yourself. The Trig and Echo pins are 4 and 2, while the servo rotation pins are
11 and 12 I believe. You might have to configre it a bit. But once that's done,
the rest is simple, as all that's left is to run the DLang software (install DUB
& DMD, then simply `dub` in the `visualizer` repository will build & run it),
and the visualizer will handle the rest.
