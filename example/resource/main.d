import sbylib.graphics;
import sbylib.editor;
import sbylib.collision;
import sbylib.wrapper.glfw;
import root;

mixin(Register!(entryPoint));

void entryPoint(Project proj, EventContext context) {
    setupFloor(proj);
    setupBall(proj);
    setupCapture(proj);

    auto ballList = proj.get!(Ball[])("ballList");
    auto floor = proj.get!(Floor)("floor");

    enum gravity = vec3(0, -9.8, 0);
    enum deltaTime = 0.01;

    alias initialize = {
        foreach (ball; ballList) {
            ball.lVel = vec3(0);
            ball.rot = mat3.identity;
        }
		ballList[0].pos.y = -1.5;
		ballList[1].pos.y = -1.;
    };
    initialize();
    when(KeyButton.Delete.pressed).then({
        initialize();
    });

    when(KeyButton.Enter.pressed).then({
        with (GUI()) {
            text(detect(floor, ballList[0]).isNull is false ? "Hit" : "Not hit");
            waitKey();
            start();
        }
        foreach (ball; ballList) {
            with (ball) {
                lVel += gravity * deltaTime;
                pos += lVel * deltaTime;
                rot *= mat3.axisAngle(safeNormalize(aVel), (length(aVel) * deltaTime).rad);
            }
        }
    });

    AABBSet ballSet;
    with (AABBSet.Builder()) {
        foreach (ball; ballList) { add(ball); }
        ballSet = build();
    }

    foreach (ball; ballList) {
        when(ballSet.collisionDetected!(Ball)(ball)).then((Ball ball1, Ball ball2, SphereSphereResult info) {
			ball1.lVel = vec3(0);
			ball2.lVel = vec3(0);
			ball1.pos -= info.pushVector;
			ball2.pos += info.pushVector;
        });
    }

    when(ballSet.collisionDetected!(Ball, Floor)(floor)).then((Ball ball, Floor floor, PlaneSphereResult info) {
        auto v = info.pushVector(ball);
        ball.lVel = vec3(0);
        ball.pos += v;
    });

}

private void setupFloor(Project proj) {
    Floor f;
    with (Floor.Builder()) {
        auto g = GeometryLibrary().buildPlane().transform(
                mat3.axisAngle(vec3(1,0,0), 90.deg) * mat3.scale(vec3(10)));
        geometry = g;
        f = build();
        static foreach (i; 0..4)
            f._vertices[i] = g.attributeList[i].position;
        f._vertices[2..4] = [f._vertices[3], f._vertices[2]];
        f.pos = vec3(0,-2,0);
    }
    proj["floor"] = f;
}

private void setupBall(Project proj) {
    with (Ball.Builder()) {
        geometry = GeometryLibrary().buildIcosahedron(2);

        Ball[] ballList;
        foreach (i; 0..2) {
            ballList ~= build();
        }
        proj["ballList"] = ballList;
    }
}

private void setupCapture(Project proj) {
    auto canvas = proj.get!Canvas("canvas");
    auto camera = proj.get!Camera("camera");
    auto floor = proj.get!Floor("floor");
    auto ballList = proj.get!(Ball[])("ballList");
    when(Frame).then({
        with (canvas.getContext()) {
            clear(ClearMode.Color, ClearMode.Depth);
            camera.capture(floor);
            foreach (ball; ballList) camera.capture(ball);
        }
    });
}

class Floor : Entity, CollisionPlane {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin Material!(FloorMaterial);
    mixin ImplUniform;
    mixin ImplBuilder;
    mixin ImplAABB;

    vec4[4] _vertices;

    override vec3[4] vertices() {
        vec3[4] r;
        static foreach (i; 0..4) r[i] = (worldMatrix * _vertices[i]).xyz;
        return r;
    }
}

class Ball : Entity, CollisionSphere {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin Material!(BallMaterial);
    mixin ImplUniform;
    mixin ImplBuilder;
    mixin ImplAABB;

    this() {
        this.scale = radius;
    }

    override vec3 center() { return pos;}

    override float radius() { return 0.2; }

    vec3 lVel = vec3(0);
    vec3 aVel = vec3(0);
}

class FloorMaterial : Material {
    mixin VertexShaderSource!q{
        #version 450

        in vec4 position;
        in vec2 uv;
        out vec2 uv2;
        uniform mat4 worldMatrix;
        uniform mat4 viewMatrix;
        uniform mat4 projectionMatrix;

        void main() {
            gl_Position = projectionMatrix * viewMatrix * worldMatrix * position;
            uv2 = uv;
        }
    };

    mixin FragmentShaderSource!q{
        #version 450

        in vec2 uv2;
        out vec4 fragColor;

        float value1() {
            const float size = 0.1 / 8;
            vec2 po = mod(uv2 / (size * 2), vec2(1)) - 0.5;
            if (po.x * po.y > 0) {
                return 0.2;
            } else {
                return 0.3;
            }
        }

        float value2() {
            const float size = 0.1 / 8;
            vec2 po = mod(uv2 / (size * 2), vec2(1)) - 0.5;
            if (po.x * po.y > 0) {
                return 0.2;
            } else {
                return 0.1;
            }
        }

        float value() {
            const float size = 0.1;
            vec2 po = mod(uv2 / (size * 2), vec2(1)) - 0.5;
            if (po.x * po.y > 0) {
                return value1();
            } else {
                return value2();
            }
        }

        void main() {
            fragColor = vec4(vec3(value()), 1);
        }
    };
}

class BallMaterial : Material {
    mixin VertexShaderSource!q{
        #version 450

        in vec4 position;
        in vec3 normal;
        out vec3 vnormal;
        uniform mat4 worldMatrix;
        uniform mat4 viewMatrix;
        uniform mat4 projectionMatrix;

        void main() {
            gl_Position = projectionMatrix * viewMatrix * worldMatrix * position;
            vnormal = normal;
        }
    };

    mixin FragmentShaderSource!q{
        #version 450

        in vec3 vnormal;
        out vec4 fragColor;

        void main() {
            fragColor = vec4(vnormal * .5 + .5,1);
        }
    };
}
