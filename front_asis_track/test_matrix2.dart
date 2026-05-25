import 'package:vector_math/vector_math_64.dart';
void main() {
  final matrix = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
  matrix.setTranslationRaw(1.0, 2.0, 0.0);
  print(matrix);
}
