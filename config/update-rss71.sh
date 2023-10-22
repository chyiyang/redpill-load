# modyfy md5 value of rss.json (Pre-preparation of structures required)
while read -r model; do
  echo "Modifying rss.json for $model"
  remodel=$(echo "$model" | sed 's/DS//' | sed 's/RS/rs/' | sed 's/DVA/dva/' | sed 's/FS/fs/' )
  echo "Remodeled: $remodel"
  value=$(grep "$model" _common/kernel-bs-fb-patch-for-all/md5-chksum | grep os.md5 | awk '{print $1}')
  echo "md5: $value"
  jq --arg remodel "$remodel" --arg value "$value" '.channel.item[] |= if .BuildNum == 42962 then .model |= map(if .mUnique | contains($remodel) then .mCheckSum = $value else . end) else . end' ../rss/7.1.1/rss.json > ../rss_tmp.json
  mv ../rss_tmp.json ../rss/7.1.1/rss.json
done < models

# convert rss.xml from rss.json
tce-load -iw python
python2 convert_rss_xml71.py
