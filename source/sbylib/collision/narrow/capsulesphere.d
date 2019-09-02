module sbylib.collision.narrow.capsulesphere;

import sbylib.collision.shape.capsule : CollisionCapsule;
import sbylib.collision.shape.sphere : CollisionSphere;
import sbylib.math;
import std.typecons : Nullable, nullable;

struct CapsuleSphereResult {
    vec3 pushVector;
}

Nullable!CapsuleSphereResult detect(Capsule : CollisionCapsule, Sphere : CollisionSphere) (Sphere sphere, Capsule capsule) {
    return detect(capsule, sphere);
}

Nullable!CapsuleSphereResult detect(Capsule : CollisionCapsule, Sphere : CollisionSphere) (Capsule capsule, Sphere sphere) {
    import std : min, max;
    // (s + tv - p, v) = 0
    const s = capsule.ends[0];
    const v = capsule.ends[1] - capsule.ends[0];
    vec3 p;
    if (v == vec3(0)) {
        p = s;
    } else {
        p = s + max(0, min(1, dot(sphere.center - s, v) / lengthSq(v))) * v;
    }
    const d = p - sphere.center;

    if (lengthSq(d) > (sphere.radius + capsule.radius) ^^ 2)
        return typeof(return).init;
    return CapsuleSphereResult((sphere.radius + capsule.radius - length(d)) * safeNormalize(d)).nullable;
}
