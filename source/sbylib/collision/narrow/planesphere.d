module sbylib.collision.narrow.planesphere;

import sbylib.collision.shape.plane : CollisionPlane;
import sbylib.collision.shape.sphere : CollisionSphere;
import sbylib.math;
import std.typecons : Nullable, nullable;

enum Type { Face, Edge, Vertex }

struct PlaneSphereResult {
    vec3 _pushVector;
    Type type;

    vec3 pushVector(CollisionPlane) {
        return _pushVector;
    }

    vec3 pushVector(CollisionSphere) {
        return -_pushVector;
    }
}

auto detect(Plane : CollisionPlane, Sphere : CollisionSphere) (Sphere sphere, Plane plane) {
    return detect(plane, sphere);
}

auto detect(Plane : CollisionPlane, Sphere : CollisionSphere) (Plane plane, Sphere sphere) {
    auto pos = inverseSignPos(plane.vertices, sphere.center);
    if (pos[0] == -1)
        return toFace(plane.vertices, sphere);
    if (pos[1] == -1)
        return toEdge([plane.vertices[pos[0]], plane.vertices[(pos[0]+1)%4]], sphere);
    if (pos[0] + 1 == pos[1])
        return toVertex(plane.vertices[pos[1]], sphere);
    if ((pos[1] + 1) % 4 == pos[0])
        return toVertex(plane.vertices[pos[0]], sphere);
    assert(false);
}

private int[2] inverseSignPos(vec3[4] v, vec3 p) {
    auto base = getNormal(v[0], v[1], v[2]);
    int pos = 0;
    int[2] res = [-1,-1];
    static foreach (i; 0..4) {
        if (dot(base, getNormal(v[i], v[(i+1)%4], p)) < 0) {
            assert(pos < 2);
            res[pos++] = i;
        }
    }
    return res;
}

private auto toFace(Sphere)(vec3[4] v, Sphere s) {
    auto n = getNormal(v[0], v[1], v[2]).normalize;
    auto d = dot(n, s.center - v[0]);
    return wrapResult(n * d, s, Type.Face);
}

private auto toEdge(Sphere)(vec3[2] v, Sphere s) {
    auto vec = v[1] - v[0];
    auto l2 = lengthSq(vec);
    auto t = dot(vec, s.center - v[0]) / l2;
    if (t < 0) return wrapResult(v[0] - s.center, s, Type.Edge);
    if (t > 1) return wrapResult(v[1] - s.center, s, Type.Edge);
    return wrapResult(v[0] + vec * t - s.center, s, Type.Edge);
}

private auto toVertex(Sphere)(vec3 v, Sphere s) {
    return wrapResult(v - s.center, s, Type.Vertex);
}

private Nullable!PlaneSphereResult wrapResult(Sphere)(vec3 d, Sphere s, Type t) {
    auto l = length(d);
    if (l > s.radius) return typeof(return).init;
    return nullable(PlaneSphereResult(safeNormalize(d) * (l - s.radius), t));
}

private vec3 getNormal(vec3 a, vec3 b, vec3 c) {
    return cross(a-b, b-c);
}
