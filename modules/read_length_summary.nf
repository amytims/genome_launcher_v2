process READ_LENGTH_SUMMARY {
    input:
    path input_file

    output:
    path "${basename}_read_lengths.txt", emit: read_lengths

    script:
    if (params.hifiadaperfilt)
        basename=input_file.getBaseName(2)
        """
        zcat $input_file | awk '{if(NR%4==2) print length($1)}' > "${basename}_read_lengths.txt"

        sed -i "s/\$/\t${basename}/" ${basename}_read_lengths.txt
        """
    else
        basename=input_file.getBaseName(1)
        """
        samtools view $input_file | cut -f 10 | awk '{print length}' > "${basename}_read_lengths.txt"

        sed -i "s/\$/\t${basename}/" ${basename}_read_lengths.txt
        """
}