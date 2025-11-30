#!/bin/bash

# Tag all commits with iOS-NNN format
cd "/Users/suzukigashin/SFC-CNS Dropbox/Gashin Suzuki/dev/miterundesu/miterundesu-ios/miterundesu"

counter=1
git log --reverse --format="%H" | while read commit_hash; do
    tag_name=$(printf "iOS-%03d" $counter)
    if ! git tag -l | grep -q "^${tag_name}$"; then
        git tag "$tag_name" "$commit_hash"
        echo "Created tag: $tag_name for commit: $commit_hash"
    else
        echo "Tag already exists: $tag_name"
    fi
    counter=$((counter + 1))
done

echo ""
echo "Total iOS tags created: $(git tag | grep -c '^iOS-')"
