# 画像から線画の描画
[すで](https://qiita.com/2zn01/items/5b8805e8791afe75f852)にあった。

AIメーカーの課金モデル
https://note.com/2zn01/n/n9384ef97e251

Stripeはいろいろと課金できそう。覚えておいてもいい。
https://qiita.com/tomodian/items/88643a7337789caea5db

pdf変換するだけのツールが収益を得ている。
https://thebridge.jp/2015/09/smallpdf-interview
ただ、これのこだわりポイントは、ローカライズはきちんと翻訳者を使ったところ、そのあたりの丁寧さは良かったのだろう。日本語だとしても、
怪しい日本語のWebサイトは使わない。

## [Cloud Functions](https://cloud.google.com/functions?hl=ja)
* 料金体系が消費したリソースで決まる。App Engineとは異なる料金体系。
* Endpointごとに異なるDependency
タイムアウト成約が9分なのがつらそう。ここに収められるようにできるか？

ここで、かなり実行が厳しくなったので、Cloud Functionsからテストしたのは良かった。
opencvやpytorchがインストールできることを確認できたのは良かった。

ハマったの↓

Note: Make sure your source files are at the root of the ZIP file, rather than a folder containing the files.
