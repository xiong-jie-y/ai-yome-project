機械学習とディープラーニングの基礎を学ぶに当たって、
CS231nの資料は割と良くて、その資料を読んで感じをつかむのはありかと思います。

確率統計がベースとなる一般的な法則は割と生き残りますが、
テクニック面は頻繁に変わるので、一般的な法則だけ勉強しておくのは価値があります。

陳腐化しない部分だけ。（機械学習の知識）

## Setting Up the models
* Normalizationでデータの広がりを均一化。それにより、NNの学習がうまく行く。(なぜ？)
* preprocessingを刷る場合、学習データの分布の統計量を使ってやる。inferenceフェーズでも同じ統計量を使う。
* batchnormやL2 Regularizationを使いましょう。

## Vializing what convnet learns
* これはネットワーク依存すぎる
* t-SNEを使ったembeddingの可視化は使えそう。

## Linear Classification
* cross entropy lossとかSVMのLossとか損失関数は一般的な最適化の形なので学習には良さそう。
* hinge lossとcross entropyのち外

## Transfer Learning
* なし
