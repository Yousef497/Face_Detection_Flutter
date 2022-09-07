import 'package:camera/camera.dart';
import 'package:face_detection/face_detector.dart';
import 'package:face_detection/utils_scanner.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  bool isWorking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face>? facesList;
  CameraDescription? description;
  CameraLensDirection cameraDirection = CameraLensDirection.front;

  initCamera()async{
    description = await UtilsScanner.getCamera(cameraDirection);
    cameraController = CameraController(description, ResolutionPreset.medium);
    faceDetector = FirebaseVision.instance.faceDetector(const FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      mode: FaceDetectorMode.fast
    ));

    await cameraController!.initialize().then((value){
      if(!mounted)
        return;

      cameraController!.startImageStream((imageFromStream) => {
        if(!isWorking){
          isWorking = true,
          performDetectionOnStreamFrames(imageFromStream),
        }
      });
    });
  }


  dynamic scanResults;
  performDetectionOnStreamFrames(CameraImage cameraImage)async{
    UtilsScanner.detect(
        image: cameraImage,
        detectInImage: faceDetector!.processImage,
        imageRotation: description!.sensorOrientation,
    ).then((dynamic results){
      setState(() {
        scanResults = results;
      });
    }).whenComplete((){
      isWorking = false;
    });
  }


  @override
  void initState(){
    super.initState();
    initCamera();
  }

  @override
  void dispose(){
    super.dispose();
    
    cameraController?.dispose();
    faceDetector!.close();
  }

  
  Widget buildResult(){
    if(scanResults == null || cameraController == null || !cameraController!.value.isInitialized)
      return const Text("");
    
    final Size imageSize = Size(cameraController!.value.previewSize.height, cameraController!.value.previewSize.width);

    CustomPainter customPainter = FaceDetectorPainter(imageSize, scanResults, cameraDirection);
    return CustomPaint(
      painter: customPainter,
    );
  }

  toggleCameraToFrontOrBack()async{
    if(cameraDirection == CameraLensDirection.back)
      cameraDirection = CameraLensDirection.front;
    else
      cameraDirection = CameraLensDirection.back;

    await cameraController!.stopImageStream();
    await cameraController!.dispose();

    setState(() {
      cameraController = null;
    });

    initCamera();
  }
  
  
  @override
  Widget build(BuildContext context) {

    List<Widget> stackWidgetChildren = [];
    size = MediaQuery.of(context).size;

    if(cameraController != null){
      stackWidgetChildren.add(
        Positioned(
          top: 0,
          left: 0,
          width: size!.width,
          height: size!.height - 150,
          child: Container(
            child: (cameraController!.value.isInitialized) ?
            AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController),
            )

            : Container(),
          ),
        )
      );
    }
    
    stackWidgetChildren.add(
      Positioned(
        top: 0,
        left: 0,
        width: size!.width,
        height: size!.height - 150,
        child: buildResult(),
      )
    );

    stackWidgetChildren.add(
        Positioned(
          top: size!.height - 150,
          left: 0,
          width: size!.width,
          height: 150,
          child: Container(
            margin: EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: (){toggleCameraToFrontOrBack();},
                    icon: Icon(Icons.cached, color: Colors.white,),
                    iconSize: 30,
                    color: Colors.black,
                )
              ],
            ),
          ),
        )
    );

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("Face Detection"),
        ),
      ),


      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackWidgetChildren,
        ),
      ),
    );
  }
}
