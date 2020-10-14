## 作ったもの
一文で言うと、YouTube上の動画など、単眼カメラで撮影された動画から、ダンスモーションを抽出し、VMDフォーマットで出力するプログラムを作りました。

次の動画のようなモーションを抽出できます。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">動画からダンスモーションの抽出。時系列考慮した２ステージの3Dポーズ推定を使った。動画のフレームレートが十分であれば良い感じに抽出できる。<br><br>元のダンスとの比較動画：<a href="https://t.co/iOPOKI40ay">https://t.co/iOPOKI40ay</a> <a href="https://t.co/DFtRtr3IXg">pic.twitter.com/DFtRtr3IXg</a></p>&mdash; Xiong Jie (@_xiongjie_) <a href="https://twitter.com/_xiongjie_/status/1193169085326123008?ref_src=twsrc%5Etfw">November 9, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

これは、私が、現在取り組んでいる[仮想彼女プロジェクト](https://www.patreon.com/xiong_jie)の一環で、かわいい動きや仕草やダンスを仮想彼女AIに学習してもらうための学習データ集めに使うつもりです。他の用途にも使えるかもしれないので、今回使った3Dポーズ推定と関連手法を少しだけ記事にまとめていこうと思います。（コードや学習済みモデルは近日公開します。）

## 今回試したポーズ推定の手法
上に載せた動画に使った手法は次の2つです。

現時点では、動画から直接3Dポーズを求めるEndToEndの手法より、
一旦2Dポーズに変換した後に、3Dポーズを求める2ステージの手法の方が性能が良いとのことです。
私が採用した手法も2Dポーズを入力とした手法でした。

* (1)  動画→2Dポーズ: Efficient Online Multi-Person 2D Pose Tracking with Recurrent Spatio-Temporal Affinity Fields
* (2) 2Dポーズ→3Dポーズ: 3D Human Pose Estimation in Video with Temporal Convolutions and semi supervised training
### 2Dポーズ推定手法
この2Dポーズ推定の出力を3Dポーズ手法の入力に使います。

#### OpenPose: Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields
論文: https://arxiv.org/pdf/1812.08008.pdf

素早い動作に対しても、割と正確で安定した出力をしてくれます。

![Screenshot from 2019-11-10 14-46-57.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/204956/1dc186b4-7fa6-e4b6-0707-8e03c5a66a28.png)


各ボディパーツの自信度マップと、Part Affinity Fieldsを2次元データとして出力して、
そこから、腕をつなげるという方式で、画像中の人全てに対して並列計算できるため、
画像中の人の数に非依存の計算量となっています。
PAFはカメラの大きな動きやMotionBlurにも強いらしい。

!!! todo
    なぜ motion blurに強い？

#### Efficient Online Multi-Person 2D Pose Tracking With Recurrent Spatio Tempooral Affinity Fields
* 論文: https://arxiv.org/abs/1811.11975
* 日本語解説: https://qiita.com/masataka46/items/14b7670fedcdb979f332
  
一言で言うと、トラッキングつきで時系列を考慮した手法です。
これの出力だけ見ると、ダンスのキレの良さなどは失われておらず、
OpenPoseより安定していました。

### 3Dポーズ推定手法
3つの手法を試しました。それぞれの手法の概要は次のとおりです。

#### End To End Recovery of Human Shape and Pose
* 論文: https://arxiv.org/abs/1712.06584
* コード: https://github.com/akanazawa/hmr

EndToEndでRGB画像から、人間の形状と姿勢とカメラ姿勢を推定する手法です。
デモプログラムがあるので、それで人の画像を何枚か入れて実行してみました。
出力形状が人のシルエットと一致しませんし、キーポイントもずれていて、すぐには使えなさそうだったので、今回は利用しませんでした。

![result_hmr.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/204956/acb1e98a-4c8f-b892-6cac-d12221a1efc7.png)

![Screenshot from 2019-11-10 14-12-07.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/204956/29f37e29-ebbb-3524-174d-965ca0c1c79f.png)


このアーキテクチャでは、形状、姿勢、カメラパラメータを予測していて、教師2Dキーポイントとのずれ（MSE)と、人間のポーズ集合から学習させたDiscriminatorを損失関数として使うことで、2Dキーポイントの教師データのみで、ポーズと形状復元を学習させています。ただ、ここで使われている学習データには、ダンスでよくある姿勢が含まれていなくて、データにないと、Fake扱いにされてしまうため、ダイレクトに学習データの影響を受け、ダンス抽出には使えなさそうです。
Discriminatorの学習に使われるデータのカバレージが高ければ有用な手法となりうると思います。

#### Lifting from the Deep: Convolutional 3D Pose Estimation from a Single Images
この手法は2Dポーズから、3Dポーズを推定する手法で、
時系列は考慮していません。

![Screenshot from 2019-11-10 15-05-51.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/204956/6557f6c5-179d-6cec-bc02-c4393b6b570b.png)


また、3Dモデルのnormalizeにかなり近似手法を使っていることと、
2D->3Dモデル変換を標準化した3Dキーポイントを2Dキーポイントに投影する場合に、
最も誤差が小さい回転とスケールを求めるという最小化問題として解いていて、
3Dプロジェクションにweak perspectiveモデルを使っていることも考慮すると、
シーンによっては誤差が大きくなりそうです。

ダンス抽出に使ってみると、静止時や緩やかな動きが不安定。ただ、頭方向を回転軸とした高速な回転など、キビキビした動きを捉えています。
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">3d pose extraction project. much better than before. still have some problem converting vmd. <a href="https://t.co/aICwnM68L9">pic.twitter.com/aICwnM68L9</a></p>&mdash; Xiong Jie (@_xiongjie_) <a href="https://twitter.com/_xiongjie_/status/1190757728341364743?ref_src=twsrc%5Etfw">November 2, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

#### 3D Human Pose Estimation in Video with Temporal Convolutions and semi supervised training
* 論文: https://research.fb.com/wp-content/uploads/2019/05/3D-human-pose-estimation-in-video-with-temporal-convolutions-and-semi-supervised-training.pdf

![Screenshot from 2019-11-10 14-55-31.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/204956/1c55de26-f195-7352-5bf3-f2c61e48a59c.png)


2Dポーズの時系列データを入力として、3Dポーズを出力する手法です。
ネットワークを2つ作っており、
ボディキーポイントのrootの位置を求めるためのtrajectoryネットワークと、
body partsのrootからの相対位置を求めるネットワークの2つを使って、
カメラ空間上の位置と姿勢を推定しています。
時系列を扱うために、RNNやLSTMではなく、Dilated Convolutionを使っています。

本記事の上の方に載せたダンスの出力をしてくれて、かなり安定した出力を出してくれます。

## 使ったみた感触
変化が激しく早いアクションに対して、
すぐに使える状態ではありませんが、
FPSに対して十分ゆっくりした動作の動画が入力であれば、
十分にアクション抽出ができそうで使えるアプリもあるかもしれません。

## 今後の改善の方向
### 位置予測がZ軸に多少ずれる問題
位置予測ネットワークの入力が多少Z軸方向にずれる。
Human 3.6Mのキーポイントを想定しているが、
入力がCocoフォーマットで対応するキーポイントがない。
Cocoフォーマットでtrajectoryネットワークを学習させる。

### ポーズが少しずれる
カメラパラメータの設定が雑なので、
カメラパラメータの設定をUIから設定できるようにしたり、
動画から自動取得するようにする。

### キビキビした動作や早い回転が失われる
#### 補完やフィルタで時系列対応？
フレームごとに独立して3Dポーズ推定して、自前で補完やノイズ削減をする方向性はダンスでは動きが早い周期で大きく変化するので、
もしかしたら難しいかもしれませんが、ダンスモーション専用の補完やフィルタアルゴリズムを自分で設計するか、学習データセットにダンスモーションを追加するかありかもしれません。

#### ラベルなしデータとしてダンス動画を追加する
うまく学習できるかわかりませんが、
試してみる価値はあります。

#### 3dポーズのラベル有りのダンス動画を追加する
資金があればこのデータセット整備もできますね。
