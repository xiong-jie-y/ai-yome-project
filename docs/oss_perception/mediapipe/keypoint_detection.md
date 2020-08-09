# キーポイント検出
## 基礎知識
### カメラモデル
カメラモデルの特徴を理解しておくと、CGやCVのアルゴリズムの理解に役立ちます。
Weak Perspective ProjectionとPerspective Projectionがよく使われます。

それぞれの特徴を以下に書きます。

* Orthogonal Projection: XY平面への投影＝単にZ軸を取り除くのみ。[変換行列](https://en.wikipedia.org/wiki/Orthographic_projection)を見るとわかりやすい。
  * CGやコンピュータビジョンで使っているのは見たことがない
* [Weak Perspective Projection: ](https://en.wikipedia.org/wiki/3D_projection)
  * Orthogonal Projection + Scaling by distance from camera
  * カメラからの距離に対して十分に奥行きが小さい物体や、FOVが小さいカメラなら誤差が小さい
  * 微分可能なため機械学習モデルでよく使われる
* Perspective Projection: 
  * ピンホールカメラモデルを投影面を工学中心からセンサとは反対側に焦点f分動かしたものです。f動かすことで、画像の上下が反転しなくて、このモデルで投影した画像は扱いやすい。
  * [Unityなど3Dエンジンの描画に使われます。](https://docs.unity3d.com/ja/2018.4/Manual/PhysicalCameras.html)
* 更に複雑なモデル
  * レンズを考慮したり、光の性質（回折とか、干渉）をシミュレートする。
  * ゲームとかではなく、高度なレンダリングで使われそう。

!!! todo
    * 複雑なモデルを確認
    * Unityでカメラいじってみる
    * Orthogonal Projectionの例

## 手のキーポイント検出
### Overview
mediapipeのモデルを使えばかなり手軽にできます。

このモデルをそのまま使う場合ですが、
手のキーポイントの位置関係がわかるため、
手の形状を入力とするアルゴリズムに使えます。

例えば、ジェスチャー認識のうち、手の形状変化が重要なものはこのモデルで検出できます。
手を振る動作など、手のワールド座標上の動きを使うジェスチャーは、
このモデルのみでは厳しいです。（カメラに並行な動きならある程度は取れそうです)

### Palm Detection


### Hand Landmark Model
Hand Landmark Modelの出力は21x3の3次元点です。
ただし、この三次元点は、(x,y)が画素の位置であり、zがカメラ座標のZ軸に平衡な奥行きだと思っています。
ただ、このzに関してはかなり怪しくて、何度もissueにz軸に関する質問が立っています。
例えば、[これ](https://github.com/google/mediapipe/issues/742)。

このissueが一番しっかりした答えですが、怪しいのが、デプスとカメラ座標のZがごっちゃになっているように思えて、zが工学中心点から点への直線距離か、Z軸に平衡な奥行き化が不明確。
また、zがz_avgへの相対的な値なのか、手首のzへの相対的な値なのかも不明確。
ただ、実装と論文を見る限り、出力値は手首のzへの相対的な値で、
zはカメラ座標のZに沿ったzです。

!!! todo
    zの推定はintrinsic parameterがなくてもできる？

おそらく、モデル的にweak perspective projectionを仮定していて、
合成データセットを作る際はperspective projectionを使っているはずだが、
それだと、どこでweak projectionを仮定しているか不明確

[v0.7.6](https://github.com/google/mediapipe/releases/tag/v0.7.6)でZをnormalizeするオプションがついていますが、このnormalizeでは、おそらく、z軸の値の範囲を、
他の画像範囲でも使える形式で大体0.0-1.0の範囲で表すことを目的としている。
学習時の手のz軸の分散で割れば0.0-1.0の範囲になるはずで、
さらに奥行き方向の単位がピクセルなので、ピクセルで割れば無単位になる。
（また、このxyzをそのまま手の形状として使う場合は、手に対して、weak perspective projectionを仮定していることになる）

例えば、横幅でzを割るというルールがあれば、
画像サイズが異なっていても、アスペクト比が同じであれば、幅をzとxにかければ良い。
元のアスペクト比と、zを何で正規化したかという情報があれば元に戻せる。

角度情報を取り出したい場合は、
元のアスペクト比は重要なので元に戻す必要がある。

weak perspective projectionはカメラと物体の距離に対して、
物体の奥行きが小さくて、カメラのFOVが狭い場合は良い近似になるとのことで、
この手のケースでは問題ないはずです。

ワールド座標のZではなく、手首に対する相対デプスを求めている理由だが、

* Cropされた画像のみでは十分な情報がない。（手のサイズが固定だと仮定すると求められる気もするが。）
  * もともとの画像サイズの大小があるので、周りのものとの相対的な位置関係で求める必要がある
  * カメラの内部パラメータがあれば、3次元空間が画像空間にどういう大きさで射影されるかわかるので、カメラ内部パラメータもセットならOK。
* また、Cropされた画像（ある程度バリエーションが減った画像であれば）、学習が簡単になる

### 手のワールド座標上の三次元位置を推定する
例えば、アプリ内の何かを掴ませたいとかそういうアプリを作る場合、
手の位置を知りたいです。ただ、mediapipeでは手の各キーポイントの手首への相対的な位置のみしかわかりません。

また、mediapipeのhand trackingは推論を行うデバイスで[カメラキャリブレーションなどなしで動くアルゴリズムを提供したいらしく](https://github.com/google/mediapipe/issues/99#issuecomment-531301021)、グローバルなZ座標推定にカメラキャリブレーションが必要な現状では、3次元座標推定を提供しないとのことです。
このHand Landmark Modelでは、手首キーポイントに対する、他のキーポイントの相対的な位置はわかるが、
手のワールド空間における位置はわからない。その値を推定するためには、

* カメラの内部パラメータ
* 手首位置のZ座標の値

を推定して、これらの値で求めたZとx,y座標を元に、逆プロジェクションする必要がある。
例えば、2D->3D Liftingでは、[カメラの内部パラメータが入力として必要です。](https://research.fb.com/wp-content/uploads/2019/05/3D-human-pose-estimation-in-video-with-temporal-convolutions-and-semi-supervised-training.pdf)

嘆願ベースのデプス推定でも、[intrinsic parameterは必要な手法が大半](https://arxiv.org/pdf/2003.06620.pdf)のようだが[、カメラの内部パラメータを推定するネットワークを組み込んで](https://arxiv.org/pdf/1904.04998.pdf)、不要なものもあるようです。[camera intrinsic不要なモデルは公式コードもあり。](https://github.com/google-research/google-research/tree/master/depth_from_video_in_the_wild)

その他、ThreeDPoseなど、リアルタイムで動く3D Pose Esimationと組み合わせるという方法もあります。
この方法だと、手首と他の体のパーツの相対値も使えるため、情報量が多いと思います。
ただ、ThreeDPoseかなりの謎技術で、Qiitaを見る限り、camera intrinsicは固定値を使っている？
ネットワーク内で推定している？

!!! todo
    * ThreeDPoseEstimationの調査

### Calculatorの説明とグラフ実装

## 顔のキーポイントの検出
### Calculatorの説明とグラフ実装

## その他のキーポイント検出を追加する
### Calculatorの説明とグラフ実装
