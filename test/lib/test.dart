import 'camerax.dart';
import 'package:jni/jni.dart';

ImageCapture imageCapture = ImageCapture$Builder().build();
Executor cameraExecutor = Executor.implement(
  $Executor(execute: (runnable) => "fuck"),
);

void onClick() {
  final ImageCapture$OutputFileOptions outputFileOptions =
      ImageCapture$OutputFileOptions$Builder(File("path".toJString())).build();

  imageCapture.takePicture$1(
    outputFileOptions,
    cameraExecutor,
    ImageCapture$OnImageSavedCallback.implement(
      $ImageCapture$OnImageSavedCallback(
        onImageSaved: (ImageCapture$OutputFileResults outputFileResults) {
          // insert your code here.
        },
        onError: (ImageCaptureException error) {
          // insert your code here.
        },
      ),
    ),
  );
}
