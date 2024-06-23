import 'package:MyDerma/Screens/classifier.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

class ClassifierFloat extends Classifier {
  ClassifierFloat({int? numThreads}) : super(numThreads: numThreads);

  @override
  String get modelName => 'quantized_pruned_model_tflite.tflite';

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(127.5, 127.5);

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 1);
}