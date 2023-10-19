# TryKernel 起動処理サンプルプログラム用 Makefile

## 概要

『インターフェース』誌 2023 年 7 月号特集記事の第 2 部第 3、4 章に
掲載されている Raspberry Pi Pico (以下 Pico) 向けのサンプルプログラムを
Eclipse に頼らずにビルドするための Makefile (+α) です。

サンプルプログラムは GitHub で公開されています。<br>
https://github.com/ytoyoyama/interface_trykernel

なお、以降の説明は FreeBSD 13.2 で動作確認した結果をもとに行っています。
より詳細な情報は下記リンク先の記事を参照してください。
- 1
- 2

## ビルド環境

ビルドに必要なツールチェインと動作確認を行ったバージョンは下記のとおりです。
インストール方法は付録 A を参照してください。

- arm-none-eabi-binutils 2.41
- arm-none-eabi-gcc-13.2.0
- GNU Make 4.3

## サンプルプログラムのセットアップ

```
% git clone https://github.com/ytoyoyama/interface_trykernel.git
% git clone https://github.com/mijinco0/build_part2.git
% cp -r build_part2/ interface_tryKernel/build_part2/
% tree ./interface_tryKernel/ (抜粋)
./interface_trykernel/
├── build_part2
│      ├── libs
│      ├── LICENSE
│      ├── README.md
│      ├── sect_3
│      │      └── Makefile
│      ├── sect_4
│      │      └── Makefile
│      └── tools
│              └── picowrite.sh
├── part_2
│      ├── sect_3
│      └── sect_4
...
```

## サンプルプログラムのビルド

```
% cd path/to/interface_tryKernel/build_part2/sect_3/
% gmake
```

ビルドに成功すると sect_3/build ディレクトリに ELF ファイルが生成されます。
これを [UF2 形式](https://github.com/microsoft/uf2) に変換したい場合は
付録 B を参照してください。
UF2 ファイルを Pico のフラッシュメモリに書き込む方法は付録 C を参照してください。

## 付録 A: ツールチェインのインストール方法

### 1. 作業ディレクトリとインストール先ディレクトリの作成

ここではビルド作業用のディレクトリを ~/pico/arm-none-eabi-build、
インストール先のディレクトリを ~/pico/arm-none-eabi と想定して説明します。

```
% mkdir -p ~/pico/arm-none-eabi-build/ ~/pico/arm-none-eabi/
% cd ~/pico/arm-none-eabi-build/
% mkdir binutils-build/ gcc-build/ newlib-build/ gdb-build/
```

### 2. ソースコードを取得する

```
% cd ~/pico/arm-none-eabi-build/
% wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz
% wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
% wget wget ftp://sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz
% tar Jxf binutils-2.41.tar.xz
% tar Jxf gcc-13.2.0.tar.xz
% tar xzf newlib-4.3.0.20230120.tar.gz
```

### 3. binutils

```
% cd ~/pico/arm-none-eabi-build/binutils-build
% ../binutils-2.41/configure --target=arm-none-eabi --prefix=/home/mijinco/pico/arm-none-eabi --with-cpu=cortex-m0plus --with-no-thumb-interwork --with-mode=thumb
% gmake all install
```

いまインストールした binutils のコマンド群は以降の作業で必要となるので、
パスを通しておきます。

```
% export PATH="$PATH:~/pico/arm-none-eabi/bin"
```

### 4. gcc と libgcc

```
% cd ~/pico/arm-none-eabi-build/gcc-build
% ../gcc-13.2.0/configure --target=arm-none-eabi --prefix=/home/mijinco/pico/arm-none-eabi --with-cpu=cortex-m0plus --enable-languages=c,c++ --without-headers --with-newlib --with-no-thumb-interwork --with-mode=thumb
% gmake all-gcc install-gcc
% gmake all-target-libgcc install-target-libgcc
```
### 5. Newlib

Newlib は不要かもしれませんが、ここでは一応インストールします。

```
% cd ~/pico/arm-none-eabi-build/newlib-build
% ../newlib-4.3.0.20230120/configure --target=arm-none-eabi --prefix=/home/mijinco/pico/arm-none-eabi --disable-newlib-supplied-syscalls
% gmake all install
```

### 6. gcc (再)

Newlib への対応のため、再度 GCC を configure して make します。

```
% cd ~/pico/arm-none-eabi-build/gcc-build
% ../gcc-13.2.0/configure --target=arm-none-eabi --prefix=/home/mijinco/pico/arm-none-eabi --with-cpu=cortex-m0plus --enable-languages=c,c++ --with-newlib --with-no-thumb-interwork --with-mode=thumb
% gmake all-gcc install-gcc
```

## 付録 B: ELF を UF2 に変換する方法

ELF から UF2 へ変換するツールのソースコードが Raspberry Pi 公式の
[pico-sdk](https://github.com/raspberrypi/pico-sdk/) に
含まれています。これをコンパイルして build_part2/tools に置いてくと、
make の際に ELF から UF2 への変換まで行います。具体的な手順は下記のとおりです。

```
% git clone https://github.com/raspberrypi/pico-sdk.git --branch master
% cd pico-sdk/tools/elf2uf2/
% c++ -o elf2uf2 -I../../src/common/boot_uf2/include main.cpp
% cp elf2uf2 path/to/interface_trykernel/build_part2/tools/
```

## 付録 C: UF2 ファイルを Pico のフラッシュメモリに書き込む方法

1. Pico の BOOTSEL ボタンを押しながら USB ケーブルでパソコンに接続する。
2. マスストレージデバイスとして認識されるので、適当なマウントポイントにマウントする。
3. UF2 ファイルをコピーする。
4. アンマウントする。

```
# mount_msdosfs /dev/da1s1 /media
# cp path/to/interface_tryKernel/build_part2/sect_3/build/blink.uf2 /media
# umount /media
```

これを自動で行うシェルスクリプトを build_part2/tools/picowrite.sh に用意しました
(FreeBSD 以外では動作確認していません)。基本的には上記の手順をそのまま実行しますが、
/dev/da1s1 のところは geom コマンドの出力を解析して自動で判断する作りになっています。

```
% cd path/to/interface_tryKernel/build_part2/
# ./tools/picowrite.sh ./sect_3/build/blink.uf2
```
