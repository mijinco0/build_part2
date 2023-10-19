#!/bin/sh

#
# Raspberry Pi Pico に UF2 ファイルを書き込むスクリプト for FreeBSD
# root 権限で実行すること
# フロー:
#   1. ターゲットデバイスを USB マスストレージデバイスとして PC に接続する
#   2. geom コマンドで書き込み先フラッシュメモリのデバイスノードを探す
#   3. マウントする
#   4. cp コマンドで .uf2 ファイルをコピーする
#   5. アンマウントする
#

if [ $# -lt 1 ]; then
    echo "usage: picowrite uf2file" 1>&2
    exit 1
fi

DISKLIST=`geom disk list`
RE_GEOM="Geom name: "
RE_DESC="descr: "
RE_PICO="RPI RP2"
DISKNAME=""
DESC=""

# ディスクを特定する
while read line; do
    line=`echo $line`    # 前後の空白を削除する
    if [ `expr "$line" : "$RE_GEOM"` -ge ${#RE_GEOM} ]; then
        DISKNAME=`echo $line | sed -e "s/$RE_GEOM//"`
        continue
    fi

    if [ `expr "$line" : "$RE_DESC"` -ge ${#RE_DESC} ]; then
        DESC=`echo $line | sed -e "s/$RE_DESC//"`
        if [ `expr "$DESC" : "$RE_PICO"` -ge ${#RE_PICO} ]; then
            break
        else
            DESC=""
        fi
    fi
done <<EOF
$DISKLIST
EOF

if [ "$DESC" = "" ]; then
    echo "device not found."
    exit 1
fi

PARTLIST=`geom part list "$DISKNAME"`
RE_PROV="Providers:"
RE_NAME="1. Name: "
NODE=""

# パーティションを特定する
while read line; do
    line=`echo $line`    # 前後の空白を削除する
    if [ `expr "$line" : "$RE_PROV"` -ge ${#RE_PROV} ]; then
        read line
        NODE=`echo $line | sed -e "s/$RE_NAME//"`
        NODE="/dev/$NODE"
        break;
    fi
done <<EOF
$PARTLIST
EOF

if [ "$NODE" = "" ]; then
    echo "device not found."
    exit 1
fi

echo -n "copy $1 to $NODE ($DESC)... "

mount_msdosfs $NODE /media
cp $1 /media
umount /media

echo "done."
