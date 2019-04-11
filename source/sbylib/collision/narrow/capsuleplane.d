module sbylib.collision.narrow.capsuleplane;

import sbylib.collision.shape.plane : CollisionPlane;
import sbylib.collision.shape.capsule : CollisionCapsule;
import sbylib.math;
import std.typecons : Nullable, nullable;

enum Type { Face, Edge, Vertex }

struct CapsulePlaneResult {
    vec3 _pushVector;
    Type type;

    vec3 pushVector(CollisionPlane) {
        return _pushVector;
    }

    vec3 pushVector(CollisionCapsule) {
        return -_pushVector;
    }
}

auto detect(Capsule : CollisionCapsule, Plane : CollisionPlane)
    (Capsule capsule, Plane plane) {
    return detect(plane, capsule);
}

Nullable!(CapsulePlaneResult) detect(Plane : CollisionPlane, Capsule : CollisionCapsule)
    (Plane plane, Capsule capsule) {
    import std.algorithm : map, maxElement;
    import std.math : abs;

    const p0 = plane.vertices[0];
    const n = normalize(cross(plane.vertices[0] - plane.vertices[1], plane.vertices[1] - plane.vertices[2]));

    // exclude the obvious pattern
    const d1 = abs(dot(capsule.ends[0] - p0, n));
    const d2 = abs(dot(capsule.ends[1] - p0, n));
    if (d1 > capsule.radius * 2 && d2 > capsule.radius * 2) return typeof(return).init;

    const r = segPoly(capsule.ends, n, plane.vertices);
    if (r.dist > capsule.radius) return typeof(return).init;

    const depth = capsule.ends[].map!(end => dot(p0 - end, n)).maxElement + capsule.radius;
    return nullable(CapsulePlaneResult(r.pushVector * depth));
}

private auto segPoly(const vec3[2] ends, const vec3 n, const vec3[] ps) {
    // 平行でないとき
    //   線分が完全にポリゴン(平面)の片側に寄っている場合
    //     線分の端点が面領域に入っているとき
    //       1. 線分の端点とポリゴンの垂線ベクトル
    //     線分の端点が面領域に入っていないとき
    //       2. 辺と端点との最接近ベクトル
    //   線分が平面の両側に存在している場合
    //     線分がポリゴンを貫いているとき
    //       3. 0ベクトル(線分がポリゴンを貫いている)
    //     線分がポリゴンの横を通っているとき
    //       4. 辺と線分との最接近ベクトル
    // 平行なとき, 線分が点になっているとき
    //   線分が完全にポリゴンの面領域に収まっているとき
    //     5. 線分のどこかの点とポリゴンの垂線ベクトル
    //   線分がポリゴンの面領域からはみ出ているとき
    //     6. 辺と線分との最接近ベクトル

    // 距離が正のとき、つまり線分がポリゴンを貫いていないときはめり込み解消ベクトル=最小距離ベクトルになるが、
    // 貫いているときはめりこみ解消ベクトルは異なる
    // このとき、ベクトルの候補は
    //   1. ポリゴンの法線
    //   2. 辺と線分の外積
    // なお、返り値の法線は必ずポリゴンの表方向にしか押し出さないとする

    import std.algorithm : map, all, clamp, reduce;
    import std.range : iota;
    import std.math : abs;

    struct PolySegResult {
        float dist;
        vec3 pushVector;
    }

    const v = ends[1] - ends[0];
    const denom = dot(v, n);

    alias min = (a, b) => a.lengthSq < b.lengthSq ? a : b;

    if (denom != 0) {
        const t1 = clamp(dot(ps[0] - ends[0], n) / denom, 0, 1);
        const p = ends[0] + t1 * v;
        auto ss = 4.iota.map!(i => dot(n, cross(ps[(i+1)%$] - ps[i], ps[i] - p)));
        if (ss.all!(s => s > 0) || ss.all!(s => s < 0)) {
            if (t1 == 0 || t1 == 1) {
                // 線分が片側に寄っているとき
                // 1
                const dist = abs(dot(ps[0] - p, n));
                return PolySegResult(dist, n);
            } else {
                // 3
                return PolySegResult(0, n);
            }
        } else {
            // 2, 4
            const r = 4.iota.map!(i => segseg(ends, [ps[i], ps[(i+1)%$]])).reduce!min;
            return PolySegResult(r.length, n);
        }
    } else {
        auto ss0 = 4.iota.map!(i => dot(n, cross(ps[(i+1)%$] - ps[i], ps[i] - ends[0])));
        auto ss1 = 4.iota.map!(i => dot(n, cross(ps[(i+1)%$] - ps[i], ps[i] - ends[1])));
        const sInFaceRegion = ss0.all!(s => s > 0) || ss0.all!(s => s < 0);
        const eInFaceRegion = ss1.all!(s => s > 0) || ss1.all!(s => s < 0);
        if (sInFaceRegion && eInFaceRegion) {
            //ポリゴンは凸形状なので、端点が両方とも面領域に入っていれば全体が面領域に入っている
            // 5
            const dist = abs(dot(ps[0] - ends[0], n));
            return PolySegResult(dist, n);
        } else {
            // 6
            const r = 4.iota.map!(i => segseg(ends, [ps[i], ps[(i+1)%$]])).reduce!min;
            return PolySegResult(r.length, n);
        }
    }
}

private vec3 segseg(const vec3[2] ends0, const vec3[2] ends1) {
    import std.algorithm : clamp;

    if (ends0[0] == ends0[1]) {
        if (ends1[0] == ends1[1]) {
            // point & point
            return ends0[0] - ends1[0];
        } else {
            // point & line
            return -segPoint(ends1, ends0[0]);
        }
    } else {
        if (ends1[0] == ends1[1]) {
            // point & line
            return +segPoint(ends0, ends1[0]);
        }
    }
    const v1 = normalize(ends0[1] - ends0[0]);
    const v2 = normalize(ends1[1] - ends1[0]);
    const d1 = dot(ends1[0] - ends0[0], v1);
    const d2 = dot(ends1[0] - ends0[0], v2);
    const dv = dot(v1, v2);
    float denom = 1 - dv * dv;
    if (denom > 0) {
        denom = 1 / denom;
        const t1 = (d1 - dv * d2) * denom;
        const t2 = (d1 * dv - d2) * denom;
        if (0 <= t1 && t1 <= 1) {
            if (0 <= t2 && t2 <= 1) {
                // line & line
                const p1 = ends0[0] + t1 * v1;
                const p2 = ends1[0] + t2 * v2;
                return p1 - p2;
            } else {
                // line & point
                const t2c = clamp(t2, 0, 1);
                const p2 = ends1[0] + t2c * v2;
                return segPoint(ends0[0], v1, p2);
            }
        } else {
            if (0 <= t2 && t2 <= 1) {
                // line & point
                const t1c = clamp(t1, 0, 1);
                const p1 = ends0[0] + t1c * v1;
                return -segPoint(ends1[0], v2, p1);
            } else {
                // point & point
                const t1c = clamp(t1, 0, 1);
                const t2c = clamp(t2, 0, 1);
                const p1 = ends0[0] + t1c * v1;
                const p2 = ends1[0] + t2c * v2;
                return p1 - p2;
            }
        }
    }
    // parallel
    vec3 v = ends0[0] - ends1[0];
    v -= dot(v, v1) * v1;
    return v;
}

private vec3 segPoint(const vec3[2] ends, const vec3 p) {
    return segPoint(ends[0], ends[1] - ends[0],p);
}

private vec3 segPoint(const vec3 s, const vec3 v, const vec3 p) {
    import std.algorithm : clamp;

    const l = v.length;
    const vn = v / l;
    const ps = p - s;
    const t = dot(ps, vn);
    const tc = clamp(t, 0, l);
    return s + tc * vn - p;
}
