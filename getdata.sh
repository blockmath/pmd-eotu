# Cleanup residual data
rm -rf sprites/pokemon/
rm -rf portraits/pokemon/

# Create data directories
mkdir sprites/pokemon
mkdir portraits/pokemon

# Seek out all pokemon on pmdcollab
for i in {0..1017}; do
	printf -v prl "https://spriteserver.pmdcollab.org/assets/portrait-%04d.png" $i
	printf -v url "https://spriteserver.pmdcollab.org/assets/%04d/sprites.zip" $i
	printf -v pnam "portraits/pokemon/%04d.png" $i
	printf -v fnam "%04d" $i
	curl $prl --output $pnam
	curl $url --output 'sprites.zip'
	unzip 'sprites.zip' -d $fnam
	mv $fnam "sprites/pokemon/$fnam"
	echo "Downloaded pokemon #$i"
done
