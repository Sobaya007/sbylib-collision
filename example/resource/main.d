import sbylib.graphics;
import sbylib.editor;
import sbylib.collision;
import sbylib.math;
import sbylib.wrapper.glfw;
import root;

mixin(Register!(entryPoint));

void entryPoint(Project proj, EventContext context) {
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
        ballList[0].pos.x = 0;
        ballList[1].pos.x = 0;
        ballList[0].pos.y = -1.5;
        ballList[1].pos.y = -1.;
    };
    initialize();
    when(KeyButton.Delete.pressed).then({
        initialize();
    });

    when(Frame).then({
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
            const contactPoint = (ball1.pos + ball2.pos) / 2;
            const v1 = ball1.getLocalVelocity(contactPoint);
            const v2 = ball2.getLocalVelocity(contactPoint);
			ball1.pos -= info.pushVector;
			ball2.pos += info.pushVector;
        });
    }

    when(ballSet.collisionDetected!(Ball, Floor)(floor)).then((Ball ball, Floor floor, PlaneSphereResult info) {
        const v = info.pushVector(ball);
        const contactPoint = ball.pos - safeNormalize(v) * ball.radius + v;
        ball.pos += v;
        ball.lVel = vec3(0);
    });

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

auto getLocalVelocity(Entity)(Entity e, vec3 p) {
    return e.lVel + cross(e.aVel, p - e.pos);
}
