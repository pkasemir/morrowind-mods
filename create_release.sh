
for FOLDER in "Alchemy Filtering"; do
    TAG_PREFIX=$(cat "$FOLDER/tag_prefix")
    VERSION=$(git describe --tags --exact-match --match "$TAG_PREFIX*")
    if [ -n "$VERSION" ]; then
        VERSION=${VERSION/$TAG_PREFIX/}
        ZIP="$FOLDER-$VERSION.zip"
        echo "Creating release zip $ZIP"
        rm -vf "$ZIP"
        pushd "$FOLDER"
        7z a -tzip "../$ZIP" "Data Files"
        popd
    else
        echo "Skipping $FOLDER, not tagged with $TAG_PREFIX"
    fi
done
