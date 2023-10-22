
for file in `cat models`
do 
echo "Working on $file"
cp -rp $file/7.2.0-64570 $file/7.2.1-69057
rm -f $file/7.2.1-69057/*.bsp
sed -i 's/64570/69057/g' $file/7.2.1-69057/config.json
#sed -i 's/7.2.0/7.2.0/g' $file/7.2.0-64561/config.json
#sed -i 's/redpill-linux-v4.4.180+.ko/redpill-linux-v4.4.302+.ko/g' $file/7.2.0-64561/config.json

done

