version 1.0

task tblastn {
  input {
    String samplename
    File vfdb
    File subject
    Float evalue = 0.001
    Int max_hsps = 1
    Int percent_identity = 90
    String docker = "staphb/blast:2.14.0"
  }

  command <<<
    # version
    tblastn -version | grep tblastn | cut -d " " -f2 > VERSION

    # tblastn
    tblastn -query ~{vfdb} -subject ~{subject} -evalue ~{evalue} -max_hsps ~{max_hsps} -out blast.txt -outfmt 6
    awk 'BEGIN{print "qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore"};$3>=~{percent_identity} {print}' blast.txt > ~{samplename}.tblastn.tsv
    hits=$(awk '$3>=~{percent_identity} {print $1}' blast.txt | tr '\n' ', ' | sed 's/.$//')
 
    if [ -z "$hits" ]
    then
      echo "No blast hit!" > GENES
    else
      echo $hits > GENES
    fi
  >>>

  output {
    File blast_results = "~{samplename}.tblastn.tsv"
    String genes = read_string("GENES")
    String blast_docker = docker
    String blast_version = read_string("VERSION")
  }

  runtime {
      docker: "~{docker}"
      memory: "2 GB"
      cpu: 2
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}

  