# 回転の実装
## Python
Rotationモジュールは内部的にはquaternionで保存していて、
applyはmatrixとベクトルの演算、__mul__(回転の合成)は、quaternion同士の積として、実装している。
なので、これらの性質を引き継ぐと考えていいです。

## C++
