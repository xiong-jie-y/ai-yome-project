# 実装の加速に役立つ機能
## Glossory
* Streamlitスクリプト: `streamlit run`で実行されるスクリプト

## 開発効率化の検討
Streamlitは動的な画面書き換えがPythonモジュールのみで超低コストでできる。
これは開発時のリッチな出力画面と捉えることもできて、
今までとは異なるソフトウェア開発方法を模索できるかもしれない。

### リロード機能
リロード機能のおかげで、
実装サイクルをかなり早めることができる。
これができない条件下では、少し不便になるが、
それでもインタラクティブコンポーネントを使ったパラメータ調整は使える。
.soなどDynamic Libraryはうまくリロードできないが、
Pythonはほとんど困ることはない。

#### Pythonモジュール
Pythonモジュールのリロードはほぼうまくできている。
一点だけできなかったのは、ssh上でstreamlitを動かして、
remoteからアクセスした場合に、streamlitコマンドを実行したパス以下のモジュールを絶対importで読み込んでいる場合に、モジュール変更時のリロード時にエラーがでるという問題があった。そういった問題に直面した場合、下記のコードをStreamlitスクリプトの先頭に書けば問題なく動いた。

```
import sys
sys.path.append('.')
```

#### 動的ライブラリ(C++/Rust拡張)
Streamlitの標準のリロード機能では、`.so`など動的ライブラリのリロードがされず、
動的ライブラリ内の処理を変更したとしても、Streamlitスクリプトの実行結果が変わらない。
(C++ & boost pythonでは上記結果。 [起票済み](https://github.com/streamlit/streamlit/issues/1606))
Rustでは、Segmentation faultが発生した。(streamlit 0.61.0 on Python 3.7.7で試したところ、SegmentationFaultが出た。)

ここでは、`so`をリロードする機能の実装方法を検討したが、
Pythonのレイヤでstreamlitのソース変更なしという条件ではできなかった。

* [参考：C++のモジュールの作り方](https://qiita.com/mink0212/items/5a429bdc70bef2245413)
* [C++のPython拡張で便利そうなやつ](https://stackoverflow.com/questions/16731115/how-to-debug-a-python-segmentation-fault)

##### shared libraryを使う方法
boost-pythonを使って実装した`.so`ファイルであれば、
import構文でimportして、Pythonモジュールのように扱えるし、
そうでない`.so`ファイルでも、ctypesモジュールを使えばロードできる。
（ただし、pythonモジュール内で.so内の関数の引数と戻り値の型を記述する必要がある。)

これらの方法を使ってロードした`.so`をpythonプロセスから[削除できないよう](https://stackoverflow.com/questions/437589/how-do-i-unload-reload-a-python-module/487718#487718)。なので、[Jupyter](https://stackoverflow.com/questions/39878103/jupyter-notebook-does-not-reload-boost-python-module)やIPythonで使っているautoreloadモジュールも正しくリロードできないし、importlibのreloadモジュールもできない。streamlitもできなかった。

##### メモ
soとかdynamic link。
subprocessにしてスクリプトを実行する。
streamlitのリッチな描画APIを別スクリプトと共有するなんて難しそう。
soの手動クローズと再ロード。

* https://stackoverflow.com/questions/50964033/forcing-ctypes-cdll-loadlibrary-to-reload-library-from-file

* https://stackoverflow.com/questions/20339053/in-python-how-can-one-tell-if-a-module-comes-from-a-c-extension
* https://stackoverflow.com/questions/8295555/how-to-reload-a-python3-c-extension-module

### インタラクティブコンポーネント


### 描画機能


### UIの分割
#### Keyの重複防止
Streamlitのinteractive UI(のみ？）には、ユニークなKeyが設定されていて、UIの値が変更されると、そのKeyを使ってWebSockテストet経由でUIの値を取っているようです。
このKeyは表示するよう設定された文字列などから自動生成されますが、
この自動生成に頼ると、汎用的なUIを自分で作成して、複数ヶ所から汎用UIを利用した場合に、
キーの重複が発生してエラーになります。

~~UIのユニーク値を手軽に得る方法が必要です。~~

~~1. StreamlitのAPIは並列的に呼び出されることはありません。（現状）なので、time.count()などを使って、TickCountをキーとすると、全てユニークになります。
2. 汎用コンポーネントのライフタイム期間が同じであれば、pythonのクラスIDが使えますが、そのよな状況は少なそうです。（PythonのクラスIDはインスタンスが割り当てられているメモリアドレスを元に作られていて、同時に存在するオブジェクトのIDは変わらないからです。タイミングが変わるとGCによってメモリ解放されてIDが重複する可能性もあります。（確率は低いかもしれませんが））~~

~~なので、1がおすすめです。~~

この方法でユニーク値を取るとスクリプト再実行時に値が変わるので、
ユーザが操作した結果を取得できない。なので、毎回実行するたびに同じ値になる、
また、連番のIDを発行していくという方法も有るが、これだと、条件分岐で
UIが変わる場合にIDが変わってしまうという欠点がある。

なので、streamlitの表示を行うコンポーネントでは、
必ず、keyを名前引数として受け取るようにしておいて、
そのキーを使って、内部的な名前のユニーク性を担保するようにします。

#### UIのテスト
テスト用のDashboardを作ればいいです。
Seleniumを使えばテストの自動化ができます。

#### 表示箇所から切り離し
今の所、sidebarかメインページのどちらかへの表示しか（標準では）できませんが、
これらをオブジェクトとして扱って外から渡せるようにしたい。

!!! todo
    やる