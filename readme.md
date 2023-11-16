# 後期実験「マイクロプロセッサの設計と実装」
## アーキテクチャ
### バージョン2.2: 5サイクル・パイプライン
#### 更新内容
- EX　→　EX + MA　に変更
- Loadした値をEXで使用するときは1クロックストールさせる
#### パフォーマンス
50MHzでのコンパイル結果
![V2.2コンパイル結果](./fig/v2.2_50MHz.png)
50MHzでのシミュレーション結果
```
//TODO
```

## 歴代アーキテクチャ
### バージョン2.1
分散RAM→Block RAM

### バージョン2: 4サイクル・パイプライン
#### パイプラインステージ
- IFステージ: PCを代入し(posedge)、ROMから命令を読み込む(negedge)
- IDステージ: 命令をデコードし、レジスタからオペランドを読み込む
- EXステージ: ALUで演算を行い(posedge)、メモリ読み書きがあれば実行する(negedge)
- WBステージ: レジスタに結果を書き込む
#### 工夫
- デフォルトでPC<=PC+4で計算する(常に分岐しないと予測する)ことで、デコード待ちのストールが不要
- フォワーディングを行うことで、EXステージでのレジスタ書き込み待ちのストールが不要
![V2アーキテクチャ](./fig/v2.png)
#### パフォーマンス
~~100MHzで35MHzで動作？~~ →もっと小さい。10MHzくらい？
とりあえず5MHz。
```
// Simulation Result
// TODO: FPGAで実行し、置換
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 615447789
Total time (secs): 17
Iterations/Sec   : 35
Iterations       : 600
Compiler version : GCC13.2.0
Compiler flags   : 
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0xbd59
Correct operation validated. See readme.txt for run and reporting rules.
```

### バージョン1: 5サイクル・非パイプライン
![V1アーキテクチャ](./fig/v1.png)
### パフォーマンス
```
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1100031610
Total time (secs): 13
Iterations/Sec   : 23
Iterations       : 300
Compiler version : GCC13.2.0
Compiler flags   : 
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x5275
Correct operation validated. See readme.txt for run and reporting rules.

```