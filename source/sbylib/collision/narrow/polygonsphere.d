module sbylib.collision.narrow.polygonsphere;

import sbylib.collision.shape.polygon : CollisionPolygon;
import sbylib.collision.shape.sphere : CollisionSphere;
import sbylib.math;
import std.typecons : Nullable, nullable;

enum Type { Face, Edge, Vertex }

struct PolygonSphereResult {
    vec3 _pushVector;
    Type type;

    vec3 pushVector(CollisionPolygon) {
        return _pushVector;
    }

    vec3 pushVector(CollisionSphere) {
        return -_pushVector;
    }
}

auto detect(Polygon : CollisionPolygon, Sphere : CollisionSphere) (Sphere sphere, Polygon polygon) {
    return detect(polygon, sphere);
}

auto detect(Polygon : CollisionPolygon, Sphere : CollisionSphere) (Polygon polygon, Sphere sphere) {
    auto pos = inverseSignPos(polygon.vertices, sphere.center);
    if (pos[0] == -1)
        return toFace(polygon.vertices, sphere);
    if (pos[1] == -1)
        return toEdge([polygon.vertices[pos[0]], polygon.vertices[(pos[0]+1)%$]], sphere);
    if (pos[0] + 1 == pos[1])
        return toVertex(polygon.vertices[pos[1]], sphere);
    if ((pos[1] + 1) % polygon.vertices.length == pos[0])
        return toVertex(polygon.vertices[pos[0]], sphere);
    assert(false);
}

private int[2] inverseSignPos(vec3[] v, vec3 p) {
    auto base = getNormal(v[0], v[1], v[2]);
    int pos = 0;
    int[2] res = [-1,-1];
    foreach (i; 0..v.length) {
        if (dot(base, getNormal(v[i], v[(i+1)%v.length], p)) < 0) {
            assert(pos < 2);
            res[pos++] = cast(int)i;
        }
    }
    return res;
}

private auto toFace(Sphere)(vec3[] v, Sphere s) {
    auto n = getNormal(v[0], v[1], v[2]).normalize;
    auto d = dot(n, s.center - v[0]);
    return wrapResult(n * d, s, Type.Face);
}

private auto toEdge(Sphere)(vec3[] v, Sphere s) {
    const vec = v[1] - v[0];
    const l2 = lengthSq(vec);
    const t = dot(vec, s.center - v[0]) / l2;
    if (t < 0) return wrapResult(v[0] - s.center, s, Type.Edge);
    if (t > 1) return wrapResult(v[1] - s.center, s, Type.Edge);
    return wrapResult(v[0] + vec * t - s.center, s, Type.Edge);
}

private auto toVertex(Sphere)(vec3 v, Sphere s) {
    return wrapResult(v - s.center, s, Type.Vertex);
}

private Nullable!PolygonSphereResult wrapResult(Sphere)(vec3 d, Sphere s, Type t) {
    auto l = length(d);
    if (l > s.radius) return typeof(return).init;
    return nullable(PolygonSphereResult(safeNormalize(d) * (l - s.radius), t));
}

private vec3 getNormal(vec3 a, vec3 b, vec3 c) {
    return cross(a-b, b-c);
}
