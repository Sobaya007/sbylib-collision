module sbylib.collision.narrow.detect;

import sbylib.collision.narrow;

alias CollisionResult(Type1, Type2) = typeof(detect(Type1.init, Type2.init).get());
