# Metadata and variables
nPoke=1017 # how many pokemon are there, by dex number, that we want to get

bold=$(tput smso)
normal=$(tput rmso)

# Record timing data
start=`date +%s`

# Cleanup residual data
rm -rf sprites/pokemon/
rm -rf portraits/pokemon/

# Create data directories
mkdir sprites/pokemon
mkdir portraits/pokemon

# Seek out all pokemon on pmdcollab
for i in $(seq 0 $nPoke); do
	printf -v prl "https://spriteserver.pmdcollab.org/assets/portrait-%04d.png" $i
	printf -v url "https://spriteserver.pmdcollab.org/assets/%04d/sprites.zip" $i
	printf -v pnam "portraits/pokemon/%04d.png" $i
	printf -v fnam "%04d" $i
	curl $prl --output $pnam
	curl $url --output 'sprites.zip'
	unzip 'sprites.zip' -d $fnam
	mv $fnam "sprites/pokemon/$fnam"
	echo $bold "Downloaded pokemon #$i of $nPoke" $normal
done
rm sprites.zip

# Reinterpret animation XMLs as JSON/Python compliant dictionaries
echo $bold Reinterpreting XML files... $normal
python3 animparse.py 

# Report timing data
end=`date +%s`
echo $bold Operation finished in `expr $end - $start` seconds. $normal
