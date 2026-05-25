import 'package:vector_math/vector_math_64.dart';
void main() {
  var m = Matrix4.identity();
  m.setTranslationRaw(1.0, 2.0, 0.0);
  m.scale(2.0, 2.0, 1.0);
  print(m);
}
