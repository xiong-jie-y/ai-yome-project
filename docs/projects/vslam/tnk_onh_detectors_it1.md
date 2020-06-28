# Mediapipeで物体Aが物体Bの内部にどの程度入っているか計算する(1st iteration)
## 開発方針
内部に入っているかの計算をする場合、
画像空間上でアルゴリズムを組んでいくことも出来るし、
三次元空間上で組んでいくこともできる。

これはアプリの目標精度にもよるけど、
出来る限り多くのシーンで使うことを考えると、
三次元空間で組んで方向なども出したほうが良さそうです。

なので、三次元空間のモデルを作ることにする。

出力値としては、物体Aと物体Bの中心位置、速度、姿勢を出すことを目標とします。
物体Aと物体Bはどちらも肌色であり、色やエッジが似ている部分があるため、それ以上の形状を元にどこに物体A、物体Bがあるかを検知する必要があります。

出力としては、メッシュ、convexhull, bounding boxなどがありますが、
接触を計算したいわけではなく、内部にはいっている度合を計算したいだけなので、
bounding boxを採用します。(内部に入れる方はキーポイントの抽出のみで良いかもしれません。)

トラッキングにより前後の文脈からオクルージョンした場合もキーポイントやBounding Boxのサイズや方向を間違わずに検出できるようにしたい。もしくはサイズのPriorを用意しておいて、
そこからオクルージョンの対応をできるようにしたい。

あとはBounding Boxとキーポイントの交差の長さによって、
あるものを判定したい。

## 教師データを収集
3D Bounding Boxの学習データを効率よく集める方法として、
[mediapipeで使われている方法](https://ai.googleblog.com/2020/03/real-time-3d-object-detection-on-mobile.html)が良さそうです。
この方法では、AR合成画像と3D地図へアノテーションして、2D画像に投影する方法の組み合わせることで、アノテーションの工数を大幅に省いていて、この方法なら個人でもできそうです。

ただし、この方法で教師データを集めるには、

* 検出物体をAR表示すること
* SLAMにより地図を構築すること

が必要です。これらを１アプリで行うのは工数観点で厳しいですが、
別々には可能だと思います。[^1]
また、RGBDのデータセットを作るには、AR画像の生成のみでなく、
センサのモデルに合った点群モデル生成も必要です。

### AR合成データの作成(WIP)


### SLAM地図に対するアノテーション
SLAMを使って地図を作り、その地図に対してBounding Boxをアノテーションする。
対象物が静止物であれば、カメラの位置とカメラがその位置にいたときの点群、
及び見えていたRGB画像がわかるため、RGB to 3d bounding box, rgbd to 3d bounding boxの学習データセットを作れます。

地図づくりができるソフトウェアを今すぐ手軽に扱えそうかという観点で探しました。

* [rtabmap](http://introlab.github.io/rtabmap/)
  * Graph based SLAM。IMU活用なし、端末位置、姿勢あり。
* [open3d(Reconstruction system)](http://www.open3d.org/docs/release/tutorial/ReconstructionSystem/system_overview.html)
  * スキャンマッチング系、使えるかもしれないが、IMU活用なし、端末の位置・姿勢なし。kinect, reaslsense対応
* cartographer
  * Graph based SLAM。IMUとOdometryを組み合わせた端末姿勢、位置推定あり。
* gmapping, uamcl
  * PF系、不明
* Tadataka
  * Visual SLAMのみ。地図構築はなさそう。

パラメータ調整が大変と書かれているので多少不安ではありますが、Cartographerが最も良い地図がえられそうです。IMUを使っていて、Graph Based SLAMは全体最適を書けるフェーズがあるからです。
次点がrtabmapです。

### (Kinect or realsense) & Cartographer on ROS
#### ROSインストール(WIP)
ROS2はよ普及して！！！（他力本願）

(ROSはpython3のサポートはないようで、[python3を使うとると気をつけないといけない点やトラブルが多そう](https://qiita.com/tnjz3/items/4d64fc2d3な6b75e604ab1)なので、利便性をROS導入の工数が上回りそうなので導入は見合わせました。)

Ubuntu 18.04上でros melodicをインストールした。
その際、Cryptodomeというpythonモジュールのバージョン衝突が起こったため、
下記コマンドで上書きした。Cryptodomeのマイナーバージョンが異なるだけだが、
今後、バージョン違いにより問題が発生する可能性もある。
```
sudo apt --fix-broken install -o Dpkg::Options::="--force-overwrite"
```
今後問題が起こった場合に元のバージョンに戻せるようにwarningをメモしておく。
```
dpkg: warning: overriding problem because --force enabled:
dpkg: warning: trying to overwrite '/usr/lib/python2.7/dist-packages/Cryptodome/SelfTest/Cipher/test_vectors/AES/CBCMCT192.rsp', which is also in package python-cryptodome 3.5.1-2~bionic
```

[ROSのワークスペース作成](http://wiki.ros.org/ROS/Tutorials/InstallingandConfiguringROSEnvironment)
Python3はイレギュラーなようなので、ROSは利用しないことにしました。

#### CartographerをROSなしで利用(WIP)

### RtabmapとOpen3Dでアノテーション
[C++で書かれているアノテーションツール](https://github.com/yzrobot/cloud_annotation_tool)はある。ただ、GPLであるため、もう少しゆるいライセンスのものが良い。
rtabmapで地図生成して、カメラ位置、RGB画像、デプス画像、完成物の地図を生成できる。
フォーマットは、

* 端末位置: 選択できる。RGB[-D Datasetsのフォーマット](https://vision.in.tum.de/data/datasets/rgbd-dataset/file_formats)を利用。
を利用。
* 地図：plyとかpcd, open3dでは簡単に読み込みできる
* RGBD：RGB画像とデプス、フレームレートは端末位置のフレームレートと同じだった。

Open3Dには点群を選択するVisualizerWithEditingクラスがあるので、
これで点群を選択して、その点群を囲むBoundingBoxを自動生成して、それを使うことにする。
また、VisualizerWithKeycallbackを使えば、BoundingBoxの自動調整はできそうです。

#### Open3DのVisualizerの拡張性
Open3Dは出来る限り拡張せずに使えるVisualizerを提供することを目指している？
現時点では、あまり拡張性の幅が広くなく、キーイベントは追加できるがマウスイベントは追加できない。

* サンプル
  * http://www.open3d.org/docs/release/tutorial/Advanced/interactive_visualization.html
* 拡張できるクラス
  * [ViewControl](http://www.open3d.org/docs/release/python_api/open3d.visualization.ViewControl.html): カメラの位置などを変更できる
  * [VisualizerWithEditing](http://www.open3d.org/docs/release/python_api/open3d.visualization.VisualizerWithEditing.html#open3d.visualization.VisualizerWithEditing): 点群を選択して、それらの点群に何らかの処理をかけられるVisaulzier。[点群の編集用で点群以外は選択できないとのことです。また、２つ以上のGeometryを追加できない。](https://github.com/intel-isl/Open3D/issues/239#issuecomment-375803010)
  * [VisualzierWithKeyCallback](https://github.com/intel-isl/Open3D/blob/master/cpp/open3d/visualization/visualizer/VisualizerWithKeyCallback.h): キーコールバックを追加できるVisualizer
* GUIフレームワーク
  * [0.10.0でimguiに移行](https://github.com/intel-isl/Open3D/releases/tag/v0.10.0)
* 外部モジュール管理
  * [submodule](https://github.com/intel-isl/Open3D/compare/v0.9.0...v0.10.0#diff-8903239df476d7401cf9e76af0252622)
* ビルドシステム
  * cmake
* できないこと
  * [How to rotate a model along X axis?](https://github.com/intel-isl/Open3D/issues/617)
  * [Manipulate position coordinate of sphere by key events](https://github.com/intel-isl/Open3D/issues/1965)
  * [Visualize Point Cloud Sequentially](https://github.com/intel-isl/Open3D/issues/1961)
  * [Visualizing SLAM poses in the same window](https://github.com/intel-isl/Open3D/issues/2015)

#### Open3DへのContirbution検討
* [ガイドライン](http://www.open3d.org/docs/release/contribute/contribute.html)
* [スタイル](http://www.open3d.org/docs/release/contribute/styleguide.html#style-guide)
* [心得２](http://www.open3d.org/docs/release/contribute/contribution_recipes.html#contribution-recipes)
* [コードレビューのTips](http://www.open3d.org/docs/release/contribute/contribution_recipes.html#contribution-recipes)
* [ドキュメンテーション貢献](http://www.open3d.org/docs/release/builddocs.html#builddocs)

## 3D Bounding Box Detectionモデルの用意と学習
### モデル、FW、手法の調査
現状を見てみると、点群処理用のフレームワークの開発スタートが一件あり、
論文多数、2018年時点くらいまでのモデルはOSSで割と公開されているという印象です。
学習データのデータフォーマットはまだバラバラで、データフォーマットの要件も明示的に書かれていないので、実行しながら調査する必要があったり、モデルのデプロイもひと手間かかる。
アノテーションツールも選択肢は少ない。

[OpenLidarPerception](https://github.com/open-mmlab/OpenLidarPerceptron)を使えば、Lidar点群を入力として、3DBoundingBoxを出力とするようなモデルを用意に利用できます。
現在サポートしているのはvoxel baseの手法で、point baseの手法はまだ用意されていないようです。

[arutemaさんの点群系DNNの記事](https://qiita.com/arutema47/items/cda262c61baa953a97e9)がいい感じにまとまっています。
ざっと見る感じ、カラー画像を活用しているのは[Frustum Pointnet](https://github.com/charlesq34/frustum-pointnets)のようで、
今回はこれを活用してみようと思います。

[VoteNet](https://github.com/facebookresearch/votenet)やPointPillarはPointCloudのみに頼っており、色情報を使っていない。今回のタスクでは色情報は検出に役立つはずなので、色情報を使っているモデルを採用したい。

その他、[3D Bounding Box Detectionの手法がまとまったリスト](https://github.com/Yvanali/3D-Object-Detection)もあります。[このリスト](https://github.com/Yochengliu/awesome-point-cloud-analysis)も豊富に情報が載っています。

### Frustum Pointnet
[Frustum Pointnet](https://arxiv.org/pdf/1711.08488.pdf)はいい感じな感じがする。

#### 3D Bounding Box抽出の関連手法
* Front View image based methods
  * RGB画像と形状Prior、オクルージョンパターンを使う
  * デプス画像に直接CNNでオブジェクト検出
* BEV based methods
  * BEVにRPNを適用。小さいオブジェクトや垂直方向の複数オブジェクト検出が無理
* 3D based methods
  * スライディングウィンドウベース。絶対遅い...
  * ポイント座標のヒストグラムを特徴量とした3DBox位置とポーズ推定（速度と性能はfurstnum pointnet以下なはず？）
  * frustum pointnet

#### Frustum Pointnetの実装
[公開されているコード](https://github.com/charlesq34/frustum-pointnets)を拡張していく、姿勢が位置自由度なので、3自由度の推定を出来るように変更する。
このリポジトリには2D検出部分は含まれていないため、自前で学習する必要がある。

まずは動作確認。必要なモジュールをインストールする。Kittiデータセットを、このリポジトリで使える形式に変換したものが、pickle形式で公開されているが、これはpython2でpickleされたものでpython3で読み込む場合、[エンコードを指定したりしないといけない。](https://qiita.com/Kodaira_/items/91207a7e092f491fca43)これに注意してソースコードを変更してあとは実行するのみ。

まず、学習データセットの形式を確認する。この形式に合ったpickleファイルを保存することで、
自前データセットの学習機能を実現する。

* id_list: トラック(１インスタンスのIDリスト)
* box2d_list: 2d bounding box(各要素はshape1,4のnd.array)
  * 使われてない。関係なさそう。
* box3d_list: 3d bounding box(各要素はshape(3,8)のnd.array)
  * 順：
* input_list: 入力値。shape(n,4)のnd.array
* label_list: ？？セマンティックセグメンテションの？値？点群と同じshape
* type_list: 文字列。クラス名
* heading_list: yaw
* size_list: bounding boxのサイズ？
* frustum_angle_list: frustumの情報。座標変換のみにしか使われてなさそう。

やるべきことは２つで自前データの加工とモデルの拡張。
1000フレーム２クラスのデータを用意して、2D detectionとPointnetの学習をする。
prepare_dataでtrain,evalはground truth2Dを使って、
frustum内部の点群を抽出している。この処理を真似れば、自前データの処理ができる。
modelsのangleとdatasetクラスを変更すれば角度は増やせるはずです。

!!! todo
    * prepare_data.pyを参考に3D bounding boxデータを元にPointnet学習データを実装する
    * 2D bounding boxを学習する。

[^1]: aaaaa