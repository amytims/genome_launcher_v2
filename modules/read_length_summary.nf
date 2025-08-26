process READ_LENGTH_SUMMARY {
    input:
    path input_file

    output:
    path "${basename}_read_lengths.txt", emit: read_lengths

    script:
    basename=input_file.getBaseName(input_file.name.endsWith('.gz')? 2: 1)
    if ( params.hifiadapterfilt == "true" )
        """
        zcat $input_file | awk '{if(NR%4==2) print length}' > "${basename}_read_lengths.txt"

        sed -i "s/\$/\t${basename}/" ${basename}_read_lengths.txt
        """
    else
        """
        samtools view $input_file | cut -f 10 | awk '{print length}' > "${basename}_read_lengths.txt"

        sed -i "s/\$/\t${basename}/" ${basename}_read_lengths.txt
        """
}