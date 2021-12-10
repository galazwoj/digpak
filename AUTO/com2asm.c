/*
 *
 * A quick generator of a byte table from a binary
 *
 */

#include <stdio.h>

int main(int argc, char *argv[])
{
	FILE *fi, *fo;
	char *in_name;
	char *out_name;
	size_t i, n_read;
	unsigned char buf[9];

	fi = fo = NULL;
	fputs("COM2ASM Generating byte table for asm include from a binary\n", stderr);
	if (argc == 1 || argc > 3) {
		fputs("Usage\n", stderr);
		fputs("COM2ASM binary_file > include_file\n", stderr);
		fputs("or\n", stderr);
		fputs("COM2ASM binary_file include_file\n", stderr);	
		fputs("\n", stderr);
		return 1;
	}

	in_name = argv[1];
	fi = fopen(in_name, "rb");
	if (!fi) {
		fprintf(stderr, "file %s not found\n", in_name);
		return 2;
	}

	if (argc == 3) {
	 	out_name = argv[2] ;
		fo = fopen(out_name, "w"); 
		if (!fo) {
			fprintf(stderr, "file %s cannot create\n", out_name);
			fclose(fi);
			return 3;
		} 
	} else
		fo = stdout;			

	while((n_read = fread(buf, 1, sizeof buf, fi)) > 0) {
		fprintf(fo, "\tdb\t");
		for (i = 0; i < n_read; i++) {
			fprintf(fo, "%03xh", buf[i]);
			fprintf(fo, "%c", i < n_read-1 ? ',' : '\n');							
		}		
	}

	if (fi)
		fclose(fi);
	if (fo) 
		fclose(fo);

	return 0;
}
