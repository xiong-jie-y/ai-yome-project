## Unity上のヒューマノイド操作の基礎
### 座標系
開発画面より明らかですが、右手座標系です。


### ボーン操作の更新タイミング



### AvatorボーンをPythonから操作する方法
ZeroMQでデータのやり取りをするといいです。

#### アーキテクチャの検討
アプリに合ったアーキテクチャを選択する必要があります。

Pythonからアバターを操作する方法は色々とありますが、
今回は3つの方法を検討します。

1. Pub/Sub方式でPython側から新しいポーズデータを送信
2. Req/Res方式でRPCのようにPython側からキャラクター操作APIを呼び出す
3. Req/Res方式でUnity側からPythonのポーズ取得APIを呼び出す

#### Pub/Sub or Req/Resの選択基準
Res/ReqとPub/Subのアーキテクチャ選択は次のようにすればいいでしょう。

アルゴリズム提供側をPublisher or RES前提でクライアントが複数の場合で話しますと、
アルゴリズムの処理対象のデータを呼び出し側が選択する場合は、REQ/RESが適しています。
リクエスト時に処理対象のデータ（もしくはそれに関連する情報）を渡して、
アルゴリズム側がそれを受け取って処理すればいいからです。
RESTAPIに近い物を作りたい場合は、REQ/RESになります。

前段でもらったデータを後段に持っていく場合は、
Subscriberの方が適しているでしょう。
例えば、カメラ画像をリアルタイムで処理システムの場合、
カメラの処理がはいって、それが次々に後段に渡されていきます。
こういう後段のタイミングでデータを渡したい場合は、Pub/Subモデルになるでしょう。
もちろん後段からReq/Resでデータを渡すという手もありますが、
データ送信が片道分ですむPub/Subが良いでしょう。

私の場合、今後、共通で複数のシステムから同じプロセスの解析データにアクセスする可能性を考えると、
プロセスの処理を複数プロセスで利用したいので、Pub/Subを選択することになります。
Req/Resの場合は２つのプロセスから利用する場合、2回の呼び出しがかかるところを
1回で済ませることができて、利用プロセス分の１の処理量となります。

##### Req/Resの速度
パフォーマンス要件によりますが、
参考にするためにZeroMQでRPCした場合のRTTを計測してみました。
（全てTCP通信でやってます。）
Clientオブジェクトを保持した場合、ローカルのやり取りでは約1ms~1.5ms程度のRTTなので、
60FPS,90FPS(VR)の描画サイクル内で呼び出すのも許容範囲でしょう。

データは収集していませんが、ネットワーク経由の場合も計測してみました。
MacBookProからWiFi経由でRRTが4ms程度、iPadからが10ms程度、iPhoneからRPC呼び出しの場合は、40ms程度で最大100ms程度の遅延になります。

##### メインスレッドと通信用スレッドを分けるか？
Req/ResでUnityからPythonを呼び出す場合は、遅延と遅延の要件を見れば、スレッドを分けて非同期処理にするか、処理待ちをするか決められます。
Subscriberモデルか、Python側かｒReq/Resでデータを渡す場合、
データ受け取り用の通信用のスレッドが必要です。

#### 事例
手の動きでアバターを操作→Pub/Sub
Unityのゲーム空間のオブジェクトを受け取って、何かをする=Req/Res

例えば、今回の用にカメラ入力を使ってアバター操作をしたいケースですが、
Python側でキャラクターのポーズを生成して、Unity側に渡したいです。
Pub/SubはSubscriber側が接続先を選び、Server/ClientはClient側が接続先を選びます。

Unity上の多数のキャラクターを操作したい場合など、
複数のPythonクライアントがいる場合は、UnityをServer、Python側をクライアント側にするでしょう。接続先を選ぶべきなのはUnity側なので、Unity側はSubscriber or Clienです。
今回はUnity側の状態に依存しない処理なので、Subscriberが適していると言えます。

Unity操作APIをZeroMQ経由でPython側に提供するのは、オーバーヘッドの関係で難しそうです。
ただ、ある程度まとめて操作できるAPIにしてしまえばできそうであり、試行錯誤が必要となりそうです。

## 座標系・回転の最低限の知識
### 座標系の変換

### radianとdegreeの変換
radianは$2\pi$が二次元回転で一周分、
degreeは$360$が二次元回転で一周分です。

$$\frac{\theta}{360} = \frac{rad}{2\pi}$$

### 回転しないことの表現
quaternionなら、$(0,0,0,0)$です。

### ２つの方向ベクトルの方向が同じことを確認


