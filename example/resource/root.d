import sbylib.graphics;
import sbylib.editor;
import sbylib.collision;
import sbylib.wrapper.glfw;

mixin(Register!(root));

void root(Project proj, EventContext context) {

    setupWindow(proj);
    setupCanvas(proj);
    setupCamera(proj);

    proj.loadErrorHandler = (Exception e) {
        with (GUI()) {
            lineHeight = 18.pixel;
            background(Color(0,0,0,0.5));
            text(e.msg);
            waitKey();
            start();
        }
    };
    proj.load().then({
        setupConsole(proj);
    });

}

private void setupWindow(Project proj) {
    auto window = Window.getCurrentWindow();
    auto videoMode = Screen.getPrimaryScreen().currentVideoMode;
    window.pos = [0.pixel, 0.pixel];
    window.size = [videoMode.width.pixel/2, videoMode.height.pixel-200.pixel];

    proj["window"] = window;
}

private void setupCanvas(Project proj) {
    auto window = Window.getCurrentWindow();
    auto videoMode = Screen.getPrimaryScreen().currentVideoMode;
    with (CanvasBuilder()) {
        color.enable = true;
        depth.enable = true;
        size = [videoMode.width.pixel/2, videoMode.height.pixel-200.pixel];
        proj["canvas"] = build(window);
    }
}

private void setupCamera(Project proj) {
    with (PerspectiveCamera.Builder()) {
        near = 0.1;
        far = 10;
        fov = 90.deg;
        aspect = 1;

        auto camera = build();
        camera.pos = vec3(0);
        proj["camera"] = cast(Camera)camera;

        auto cameraControl = new CameraControl(camera);
        cameraControl.bind();
        proj["cameraControl"] = cameraControl;
    }
}

private void setupConsole(Project proj) {
    auto console = new Console(proj);
    proj["console"] = console;

    auto canvas = proj.get!Canvas("canvas");
    auto consoleControl = new ConsoleControl(canvas, console);
    proj["consoleControl"] = consoleControl;
    setupControl(proj);
}


private void setupControl(Project proj) {
    auto cameraControl = proj.get!CameraControl("cameraControl");
    auto consoleControl = proj.get!ConsoleControl("consoleControl");

    with (cameraControl()) {
        when((Ctrl + KeyButton.KeyP).pressed).then({
            cameraControl.unbind();
            consoleControl.bind();
        });
    }

    with (consoleControl()) {
        when(KeyButton.Escape.pressed).then({
            cameraControl.bind();
            consoleControl.unbind();
        });
    }
}
