import 'dart:math';
import 'package:image/image.dart';
import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

abstract class Classifier3 {
  Interpreter? interpreter;
  InterpreterOptions? _interpreterOptions;

  var logger = Logger();

  List<int>? _inputShape;
  List<int>? _outputShape;

  TensorImage? _inputImage;
  TensorBuffer? _outputBuffer;

  TfLiteType _inputType=TfLiteType.uint8;
  TfLiteType _outputType = TfLiteType.uint8;

  final String _labelsFileName = 'assets/labels_melanoma.txt';

  final int _labelsLength = 1;

  var _probabilityProcessor;

  List<String>? labels;

  String get modelName;

  NormalizeOp get preProcessNormalizeOp;
  NormalizeOp get postProcessNormalizeOp;

  Classifier3({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    _interpreterOptions!.threads = numThreads!;
  
    loadModel();
    loadLabels();
  }

  Future<void> loadModel() async {
    try {
      interpreter =
      await Interpreter.fromAsset(modelName, options: _interpreterOptions!);
      print('Interpreter Created Successfully');
      print("$modelName loaded Succcessfully....");

      _inputShape = interpreter!.getInputTensor(0).shape;
      _inputType =interpreter!.getInputTensor(0).type;
      _outputShape = interpreter!.getOutputTensor(0).shape;
      _outputType = interpreter!.getOutputTensor(0).type;

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape!, _outputType);
      _probabilityProcessor =
          TensorProcessorBuilder().add(postProcessNormalizeOp).build();
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  Future<void> loadLabels() async {
    labels = await FileUtil.loadLabels(_labelsFileName);
    if (labels!.length == _labelsLength) {
      print('$_labelsFileName loaded successfully');
    } else {
      print('Unable to load labels');
    }
  }

  TensorImage _preProcess() {
    int cropSize = min(_inputImage!.height, _inputImage!.width);
    return ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(
        _inputShape![1], _inputShape![2], ResizeMethod.nearestneighbour))
        .add(preProcessNormalizeOp)
        .build()
        .process(_inputImage!);
  }

/*  Category predict(Image image) {
    if (interpreter == null) {
      throw StateError('Cannot run inference, Intrepreter is null');
    }
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage.fromImage(image);
    _inputImage = _preProcess();
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    print('Time to load image: $pre ms');

    final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    print('Time to run inference: $run ms');

    Map<String, double> labeledProb = TensorLabel.fromList(
        labels, _probabilityProcessor.process(_outputBuffer))
        .getMapWithFloatValue();
    final pred = getTopProbability(labeledProb);

    return Category(pred.key, pred.value);
    }
*/
  Category predict(Image image) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage(_inputType);
    _inputImage?.loadImage(image);
    // _inputImage = TensorImage.fromImage(image);
    _inputImage = _preProcess();
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    print('Time to load image: $pre ms');

    final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter!.run(_inputImage!.buffer, _outputBuffer!.getBuffer());
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    print('Time to run inference: $run ms');

    print("Probability of melanoma ${_outputBuffer!.getDoubleList()}");

    var op = _outputBuffer!.getDoubleList()[0];
    var tempp;
    if (op > 0.95) {
      tempp = "Melanoma";
    }
    else {
      tempp = "Not Melanoma";
    }
    MapEntry pred = new MapEntry<String, double>(tempp, op);
    return Category(pred.key, pred.value);
  }

  void close() {
    interpreter!.close();
    }
}

MapEntry<String, double> getTopProbability(Map<String, double> labeledProb) {
  var pq = PriorityQueue<MapEntry<String, double>>(compare);
  pq.addAll(labeledProb.entries);

  return pq.first;
}

int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
  if (e1.value > e2.value) {
    return -1;
  } else if (e1.value == e2.value) {
    return 0;
  } else {
    return 1;
  }
}