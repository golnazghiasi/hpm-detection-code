function PrintDetectionResToFile(BB, ids, confidence, file_path)

file_id = fopen(file_path, 'w');

for i = 1 : length(confidence)
	name = ids{i};
	if(length(name) > 3 && name(end - 3) == '.')
		name = name(1 : end - 4);
	end
	fprintf(file_id, '%s ', name);
	fprintf(file_id, '%.2f ', BB(i, 1), BB(i, 2), BB(i, 3), BB(i, 4));
	fprintf(file_id, '%.3f\n', confidence(i));
end
