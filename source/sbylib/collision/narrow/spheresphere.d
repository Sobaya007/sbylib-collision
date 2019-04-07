module sbylib.collision.narrow.spheresphere;

import sbylib.collision.shape.sphere : CollisionSphere;
import sbylib.math;
import std.typecons : Nullable, nullable;

struct SphereSphereResult {
    vec3 pushVector;
}

Nullable!SphereSphereResult detect(Sphere1 : CollisionSphere, Sphere2 : CollisionSphere) (Sphere1 sphere1, Sphere2 sphere2) {
    auto v = sphere1.center - sphere2.center;
    auto l = length(v) - (sphere1.radius + sphere2.radius);
    if (l > 0) return typeof(return).init;
    return nullable(SphereSphereResult(safeNormalize(v) * l));
}
