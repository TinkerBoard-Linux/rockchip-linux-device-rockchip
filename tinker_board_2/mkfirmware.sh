#!/bin/bash

set -e

if ! which fakeroot &>/dev/null; then
    echo "fakeroot not found! (sudo apt-get install fakeroot)"
    exit -1
fi

USER_DATA_DIR=device/rockchip/common/images/userdata/userdata_normal
USER_DATA_DIR_TMP=rockdev/userdata_tmp

PARAMETER=device/rockchip/tinker_board_2/$RK_PARAMETER
MISC_IMG=device/rockchip/common/images/${RK_MISC:-blank-misc.img}
MKIMAGE=device/rockchip/tinker_board_2/mk-image.sh

message() {
    echo -e "\e[36m $@ \e[0m"
}

fatal() {
    echo -e "\e[31m $@ \e[0m"
    exit -1
}

mkdir -p rockdev

# Parse size limit from parameter.txt, 0 means unlimited or not exists.
partition_size_kb() {
    PART_NAME=$1
    PART_STR=$(grep -oE "[^,^:^\(]*\(${PART_NAME}[\)_:][^\)]*\)" $PARAMETER)
    PART_SIZE=$(echo $PART_STR | grep -oE "^[^@^-]*")
    echo $(( ${PART_SIZE:-0} / 2 ))
}

link_image() {
    SRC="$1"
    DST="$2"
    FALLBACK="$3"

    message "Linking $DST from $SRC..."

    if [ ! -f "$SRC" ]; then
        if [ -f "$FALLBACK" ]; then
            SRC="$FALLBACK"
            message "Fallback to $SRC"
        else
            message "warning: $SRC not found!"
            return 1
        fi
    fi

    ln -rsf "$SRC" "rockdev/$DST"

    message "Done linking $DST"
}

link_image_optional() {
    link_image "$@" || true
}

pack_image() {
    SRC="$1"
    DST="$2"
    FS_TYPE="$3"
    SIZE="${4:-$(partition_size_kb "${DST%.img}")}"
    LABEL="$5"
    EXTRA_CMD="$6"

    FAKEROOT_SCRIPT="rockdev/${DST%.img}.fs"

    message "Packing $DST from $SRC..."

    if [ ! -d "$SRC" ]; then
        message "warning: $SRC not found!"
        return 0
    fi

    cat << EOF > $FAKEROOT_SCRIPT
#!/bin/sh -e
$EXTRA_CMD
$MKIMAGE "$SRC" "rockdev/$DST" "$FS_TYPE" "$SIZE" "$LABEL"
EOF

    chmod a+x "$FAKEROOT_SCRIPT"
    fakeroot -- "$FAKEROOT_SCRIPT"
    rm -f "$FAKEROOT_SCRIPT"

    message "Done packing $DST"
}

partition_arg() {
    PART="$1"
    I="$2"
    DEFAULT="$3"

    ARG=$(echo $PART | cut -d':' -f"$I")
    echo ${ARG:-$DEFAULT}
}

pack_extra_partitions() {
    for part in ${RK_EXTRA_PARTITIONS//@/ }; do
        DEV="$(partition_arg "$part" 1)"

        # Dev is either <name> or /dev/.../<name>
        [ "$DEV" ] || continue
        PART_NAME="${DEV##*/}"

        MOUNT="$(partition_arg "$part" 2 "/$PART_NAME")"
        FS_TYPE="$(partition_arg "$part" 3)"

        SRC="$(partition_arg "$part" 5)"

        # Src is either none or relative path to device/rockchip/<name>/
        # or absolute path
        case "$SRC" in
            "")
                continue
                ;;
            /*)
                ;;
            *)
                SRC="rockdev/userdata_tmp"
                ;;
        esac

        SIZE="$(partition_arg "$part" 6 auto)"
        OPTS="$(partition_arg "$part" 7)"
        LABEL="$PART_NAME"
        EXTRA_CMD=

        # Skip existing prebuilt images
        if [ -f rockdev/$PART_NAME.img ]; then
            rm -rf rockdev/$PART_NAME.img
        fi

        # Skip boot time resize by adding a tag file
        echo $OPTS | grep -wq fixed || touch "$SRC/.fixed"

        pack_image "$SRC" "${PART_NAME}.img" "$FS_TYPE" "$SIZE" "$LABEL" \
            "$EXTRA_CMD"

        rm -rf "$SRC"
    done
}

build_dtbo() {
    rm -f $USER_DATA_DIR/overlays/*.dtbo
    for file in $USER_DATA_DIR/overlays/*.dts
    do
        dts=${file##*/}
        dtbo=${dts%.*}
        dtc -@ -O dtb -o $USER_DATA_DIR/overlays/$dtbo.dtbo $USER_DATA_DIR/overlays/$dts
    done

    mkdir -p $USER_DATA_DIR_TMP
    cp -r $USER_DATA_DIR/* $USER_DATA_DIR_TMP
    rm $USER_DATA_DIR_TMP/overlays/*.dts
    rm $USER_DATA_DIR_TMP/overlays/.gitignore
}

link_image_optional "$PARAMETER" parameter.txt
link_image_optional "$MISC_IMG" misc.img

build_dtbo
pack_extra_partitions

echo "Packed files:"
for f in rockdev/*; do
	NAME=$(basename "$f")

	echo -n "$NAME"
	if [ -L "$f" ]; then
		echo -n "($(readlink -f "$f"))"
	fi

	FILE_SIZE=$(ls -lLh $f | xargs | cut -d' ' -f 5)
	echo ": $FILE_SIZE"

	echo "$NAME" | grep -q ".img$" || continue

	# Assert the image's size smaller than parameter.txt's limit
	PART_SIZE="$(partition_size_kb "${NAME%.img}")"
	FILE_SIZE_KB="$(( $(stat -Lc "%s" "$f") / 1024 ))"
	if [ "$PART_SIZE" -gt 0 -a "$PART_SIZE" -lt "$FILE_SIZE_KB" ]; then
		fatal "error: $NAME's size exceed parameter.txt's limit!"
	fi
done

message "Images in rockdev are ready!"
