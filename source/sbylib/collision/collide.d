module sbylib.collision.collide;

enum collidable;

import sbylib.collision.shape.shape : CollisionShape;
import sbylib.collision.narrow;
import sbylib.collision.narrow.detect : CollisionResult;

auto collisionDetected(Type1 : CollisionShape, Type2 : CollisionShape)(Type1 t1, Type2 t2) {
    import sbylib.graphics : Event, when, Frame, then, until;

    auto result = new Event!(Type1, Type2, CollisionResult!(Type1, Type2));
    when(Frame).then({
        auto r = detect(t1, t2);
        if (r.isNull) return;
        result.fire(t1, t2, r.get());
    });
    return result;
}
