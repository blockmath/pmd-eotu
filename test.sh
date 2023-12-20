
for i in $(seq 0 1017); do
	printf -v fromPath "sprites/pokemon/%04d/AnimData.xml" $i
	printf -v toPath "sprites/pokemon/%04d/AnimData.json" $i
	mv $fromPath $toPath
done
