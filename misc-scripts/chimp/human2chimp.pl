use strict;
use warnings;

use Getopt::Long;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Analysis;

use InterimTranscript;
use InterimExon;
use StatMsg;
use Deletion;
use Insertion;
use Transcript;
use StatLogger;
use StatMsg;

use Utils qw(print_exon print_coords print_translation);

use Bio::EnsEMBL::Utils::Exception qw(throw info verbose warning);


{                               # block to avoid namespace pollution

  my ($hhost, $hdbname, $huser, $hpass, $hport, $hassembly, # human vars
      $hchromosome, $hstart, $hend,
      $chost, $cdbname, $cuser, $cpass, $cport, $cassembly, # chimp vars
      $dhost, $ddbname, $duser, $dpass, $dport, # destination db
      $help, $verbose, $logfile, $store);

  GetOptions('hhost=s'   => \$hhost,
             'hdbname=s' => \$hdbname,
             'huser=s'   => \$huser,
             'hpass=s'   => \$hpass,
             'hport=i'   => \$hport,
             'hassembly=s' => \$hassembly,
             'hchromosome=s' => \$hchromosome,
             'hstart=i'  => \$hstart,
             'hend=i'    => \$hend,
             'chost=s'   => \$chost,
             'cdbname=s' => \$cdbname,
             'cuser=s'   => \$cuser,
             'cpass=s'   => \$cpass,
             'cport=i'   => \$cport,
             'cassembly=s' => \$cassembly,
             'dhost=s'   => \$dhost,
             'ddbname=s' => \$ddbname,
             'duser=s'   => \$duser,
             'dpass=s'   => \$dpass,
             'dport=i'   => \$dport,
             'store'     => \$store,
             'logfile=s' => \$logfile,
             'help'      => \$help,
             'verbose'   => \$verbose);

  verbose('INFO') if($verbose); # turn on prints of info statements

  usage() if($help);
  usage("-hdbname option is required") if (!$hdbname);
  usage("-cdbname option is required") if (!$cdbname);
  usage("-ddbname option is required when -store is specified")
    if($store && !$ddbname);

  $hport ||= 3306;
  $cport ||= 3306;

  $hdbname ||= 'localhost';
  $cdbname ||= 'localhost';

  $hassembly ||= 'NCBI34';
  $cassembly ||= 'BROAD1';


  info("Connecting to chimp database");

  my $chimp_db = Bio::EnsEMBL::DBSQL::DBAdaptor->new
    (-host    => $chost,
     -dbname  => $cdbname,
     -pass    => $cpass,
     -user    => $cuser,
     -port    => $cport);

  info("Connecting to human database");

  my $human_db = Bio::EnsEMBL::DBSQL::DBAdaptor->new
    (-host    => $hhost,
     -dbname => $hdbname,
     -pass   => $hpass,
     -user   => $huser,
     -dnadb  => $chimp_db,
     -port   => $hport);


  my $dest_db;

  if($store) {
    $dest_db = Bio::EnsEMBL::DBSQL::DBAdaptor->new
      (-host   => $dhost,
       -dbname => $ddbname,
       -pass   => $dpass,
       -user   => $duser,
       -dnadb  => $chimp_db,
       -port   => $dport);

    my $analysis = Bio::EnsEMBL::Analysis->new(-logic_name => 'ensembl');
    $dest_db->get_AnalysisAdaptor->store($analysis);
  }

  StatMsg::set_logger(StatLogger->new($logfile));

  my $slice_adaptor   = $human_db->get_SliceAdaptor();
  my $gene_adaptor    = $human_db->get_GeneAdaptor();

  info("Fetching chromosomes");

  my $slices;

  if ($hchromosome) {
    my $slice = $slice_adaptor->fetch_by_region('chromosome',
                                                $hchromosome,
                                                $hstart, $hend, undef,
                                                $hassembly);
    if (!$slice) {
      throw("unknown chromosome $hchromosome");
    }

    $slices = [$slice];
  } else {
    $slices = $slice_adaptor->fetch_all('chromosome', $hassembly);
  }


  my $cs_adaptor      = $human_db->get_CoordSystemAdaptor();
  my $asmap_adaptor   = $human_db->get_AssemblyMapperAdaptor();

  my $chimp_cs = $cs_adaptor->fetch_by_name('chromosome',  $cassembly);
  my $human_cs = $cs_adaptor->fetch_by_name('chromosome', $hassembly);

  my $mapper = $asmap_adaptor->fetch_by_CoordSystems($chimp_cs, $human_cs);

  my $total_transcripts = 0;

  foreach my $slice (@$slices) {

    info("Chromosome: " . $slice->seq_region_name());
    info("Fetching Genes");

    my $genes = $gene_adaptor->fetch_all_by_Slice($slice);

    foreach my $gene (reverse @$genes) {
      info("Gene: ".$gene->stable_id);
      my $transcripts = $gene->get_all_Transcripts();

      foreach my $transcript (@$transcripts) {
        next if(!$transcript->translation); #skip pseudo genes

        print STDERR ++$total_transcripts, "\n";

        my $interim_transcript = transfer_transcript($transcript, $mapper,
                                                     $human_cs);
        my $finished_transcripts =
          create_transcripts($interim_transcript, $slice_adaptor);

        my $transcript_count = @$finished_transcripts;
        my $translation_count = 0;
        my $stop_codons_count = 0;

        if($transcript_count > 1) {
          StatMsg->new(StatMsg::TRANSCRIPT | StatMsg::SPLIT);
        }
        elsif($transcript_count== 0) {
          StatMsg->new(StatMsg::TRANSCRIPT | StatMsg::NO_SEQUENCE_LEFT);
        }

        foreach my $ftrans (@$finished_transcripts) {
          if($ftrans->translation()) {
            $translation_count++;
            my $pep = $ftrans->translate->seq();

            print STDERR "\n\n$pep\n\n";

            if($pep =~ /\*/) {
              $stop_codons_count++;
            }

            # sanity check, if translation is defined we expect a peptide
            if(!$pep) {
              print_translation($ftrans->translation());
              throw("Unexpected Translation but no peptide");
            }
          } else {
            print STDERR "NO TRANSLATION LEFT\n";
          }
        }

        # If there were stop codons in one of the split transcripts
        # report it. Report it as 'entire' if all split transcripts had
        # stops.
        if($stop_codons_count) {
          my $code = StatMsg::TRANSCRIPT | StatMsg::DOESNT_TRANSLATE;
          if($stop_codons_count == $translation_count) {
            $code |= StatMsg::ENTIRE;
          } else {
            $code |= StatMsg::PARTIAL;
          }
          StatMsg->new($code);
        }

        if(!$translation_count) {
          StatMsg->new(StatMsg::TRANSCRIPT | StatMsg::NO_CDS_LEFT);
        }

        if($translation_count) {
          if($stop_codons_count) {
            if($translation_count > $stop_codons_count) {
              StatMsg->new(StatMsg::TRANSCRIPT | StatMsg::TRANSLATES |
                          StatMsg::PARTIAL);
            }
          } else {
            StatMsg->new(StatMsg::TRANSCRIPT | StatMsg::TRANSLATES |
                         StatMsg::ENTIRE);
          }
        }

#         foreach my $ftr (@$finished_transcripts) {
#           print_three_phase_translation($ftr);
#         }

        if($store) {
          store_gene($dest_db, $gene, $finished_transcripts);
        }

      }
    }
  }
}


sub print_three_phase_translation {
  my $transcript = shift;

  return if(!$transcript->translation());

  my $orig_phase = $transcript->start_Exon->phase();

  foreach my $phase (0,1,2) {
    info("======== Phase $phase translation: ");
    $transcript->start_Exon->phase($phase);
    info("Peptide: " . $transcript->translate->seq() . "\n\n===============");
  }

  $transcript->start_Exon->phase($orig_phase);

  return;
}



###############################################################################
#
# transfer_transcript
#
###############################################################################

sub transfer_transcript {
  my $transcript = shift;
  my $mapper = shift;
  my $human_cs = shift;

  info("Transcript: " . $transcript->stable_id());

  my $human_exons = $transcript->get_all_Exons();

  if (!$transcript->translation()) { # watch out for pseudogenes
    info("pseudogene - discarding");
    return;
  }

  my $chimp_cdna_pos = 0;
  my $cdna_exon_start = 1;

  my $chimp_transcript = InterimTranscript->new();
  $chimp_transcript->stable_id($transcript->stable_id());
  $chimp_transcript->cdna_coding_start($transcript->cdna_coding_start());
  $chimp_transcript->cdna_coding_end($transcript->cdna_coding_end());

  my @chimp_exons;

 EXON:
  foreach my $human_exon (@$human_exons) {
    info("Exon: " . $human_exon->stable_id() . " chr=" . 
         $human_exon->slice->seq_region_name() . " start=". 
         $human_exon->seq_region_start());
    # info("  cdna_pos = $chimp_cdna_pos\n  cdna_exon_start=$cdna_exon_start");

    my $chimp_exon = InterimExon->new();
    $chimp_exon->stable_id($human_exon->stable_id());
    $chimp_exon->cdna_start($cdna_exon_start);
    $chimp_exon->start_phase($human_exon->phase);
    $chimp_exon->end_phase($human_exon->end_phase());

    my @coords = $mapper->map($human_exon->seq_region_name(),
                              $human_exon->seq_region_start(),
                              $human_exon->seq_region_end(),
                              $human_exon->seq_region_strand(),
                              $human_cs);

    if (@coords == 1) {
      my $c = $coords[0];

      if ($c->isa('Bio::EnsEMBL::Mapper::Gap')) {
        #
        # Case 1: Complete failure to map exon
        #

        my $entire_delete = 1;

        Deletion::process_delete(\$chimp_cdna_pos, $c->length(),
                                 $chimp_exon,
                                 $chimp_transcript, $entire_delete);

        $chimp_exon->fail(1);
        $chimp_transcript->add_Exon($chimp_exon);

      } else {
        #
        # Case 2: Exon mapped perfectly
        #

        $chimp_exon->start($c->start());
        $chimp_exon->end($c->end());
        $chimp_exon->cdna_start($cdna_exon_start);
        $chimp_exon->cdna_end($cdna_exon_start + $chimp_exon->length() - 1);
        $chimp_exon->strand($c->strand());
        $chimp_exon->seq_region($c->id());

        $chimp_cdna_pos += $c->length();
      }
    } else {
      #
      # Case 3 : Exon mapped partially
      #

      get_coords_extent(\@coords, $chimp_exon);

      if ($chimp_exon->fail()) {
        # Failed to obtain extent of coords due to scaffold spanning
        # strand flipping, or exon inversion.
        # Treat this as if the exon did not map at all.

        my $entire_delete = 1;

        Deletion::process_delete(\$chimp_cdna_pos,
                                 $human_exon->length(),
                                 $chimp_exon,
                                 $chimp_transcript, $entire_delete);

      } else {

        my $num = scalar(@coords);

        for (my $i=0; $i < $num; $i++) {
          my $c = $coords[$i];

          if ($c->isa('Bio::EnsEMBL::Mapper::Gap')) {

            #
            # deletion in chimp, insert in human
            #
            Deletion::process_delete(\$chimp_cdna_pos, $c->length(),
                                     $chimp_exon, $chimp_transcript);

          } else {
            # can end up with adjacent inserts and deletions so need
            # to take previous coordinate, skipping over gaps
            my $prev_c = undef;

            for (my $j = $i-1; $j >= 0 && !defined($prev_c); $j--) {
              if ($coords[$j]->isa('Bio::EnsEMBL::Mapper::Coordinate')) {
                $prev_c = $coords[$j];
              }
            }

            if ($prev_c) {

              my $insert_len;
              if ($chimp_exon->strand() == 1) {
                $insert_len = $c->start() - $prev_c->end() - 1;
              } else {
                $insert_len = $prev_c->start() - $c->end() - 1;
              }

              #sanity check:
              if ($insert_len < 0) {
                throw("Unexpected - negative insert " .
                      "- undetected exon inversion?");
              }

              if ($insert_len > 0) {

                #
                # insert in chimp, deletion in human
                #

                #info("before insert, CDNA_POS= $chimp_cdna_pos");

                Insertion::process_insert(\$chimp_cdna_pos, $insert_len,
                                          $chimp_exon, $chimp_transcript);

                $chimp_cdna_pos += $insert_len;
                #info("after insert, CDNA_POS= $chimp_cdna_pos");
              }
            }

            $chimp_cdna_pos += $c->length();
            #info("after match (" . $c->length(). ") CDNA_POS= $chimp_cdna_pos");
          }
        }  # foreach coord
      }
    }

    $cdna_exon_start = $chimp_cdna_pos + 1;
    # info("after exon, CDNA_POS= $chimp_cdna_pos");

    $chimp_transcript->add_Exon($chimp_exon);
  } # foreach exon

  return $chimp_transcript;
}




###############################################################################
# get_coords_extent
#
# given a list of coords returns the start, end, strand, seq_region
# of the span of the coords
#
# undef is returned if the coords flip strands, have an inversion,
# or cross multiple seq_regions
#
###############################################################################

sub get_coords_extent {
  my $coords = shift;
  my $chimp_exon = shift;

  my($start, $end, $strand, $seq_region);

  my $stat_code = StatMsg::EXON;

  print_coords($coords);

  foreach my $c (@$coords) {
    next if($c->isa('Bio::EnsEMBL::Mapper::Gap'));

    if (!defined($seq_region)) {
      $seq_region = $c->id();
    } elsif ($seq_region ne $c->id()) {
      $chimp_exon->fail(1);
      $stat_code |= StatMsg::SCAFFOLD_SPAN;
      $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
      return;
    }

    if (!defined($strand)) {
      $strand = $c->strand();
    } elsif ($strand != $c->strand()) {
      $chimp_exon->fail(1);
      $stat_code |= StatMsg::STRAND_FLIP;
      $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
      return;
    }

    if (!defined($start)) {
      $start = $c->start if(!defined($start));
    } else {
      if ($strand == 1 && $start > $c->start()) {
        $chimp_exon->fail(1);
        $stat_code |= StatMsg::INVERT;
        $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
        return;
      }
      if ($strand == -1 && $start < $c->start()) {
        $chimp_exon->fail(1);
        $stat_code |= StatMsg::INVERT;
        $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
        return;
      }

      if ($start > $c->start()) {
        $start = $c->start();
      }
    }
	
    if (!defined($end)) {
      $end = $c->end();
    } else {
      if ($strand == 1 && $end > $c->end()) {
        $chimp_exon->fail(1);
        $stat_code |= StatMsg::INVERT;
        $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
        return;
      }
      if ($strand == -1 && $end < $c->end()) {
        $chimp_exon->fail(1);
        $stat_code |= StatMsg::INVERT;
        $chimp_exon->add_StatMsg(StatMsg->new($stat_code));
        return;
      }
      if ($c->end > $end) {
        $end = $c->end();
      }
    }
  }

  $chimp_exon->start($start);
  $chimp_exon->end($end);
  $chimp_exon->strand($strand);
  $chimp_exon->seq_region($seq_region);
  $chimp_exon->cdna_end($chimp_exon->cdna_start() + $chimp_exon->length() - 1);
}

###############################################################################
# create_transcripts
#
###############################################################################

sub create_transcripts {
  my $itranscript   = shift;    # interim transcript
  my $slice_adaptor = shift;

  # set the phases of the interim exons
  # Transcript::set_iexon_phases($itranscript);

  # check the exons and split transcripts where exons are bad
  my $itranscripts = Transcript::check_iexons($itranscript);

  my @finished_transcripts;

  foreach my $itrans (@$itranscripts) {
    # if there are any exons left in this transcript add it to the list
    if (@{$itrans->get_all_Exons()}) {
      push @finished_transcripts, Transcript::make_Transcript($itrans,
                                                              $slice_adaptor);
    } else {
      info("Transcript ". $itrans->stable_id . " has no exons left\n");
    }
  }

  return \@finished_transcripts;
}



###############################################################################
# store gene
#
# Builds Ensembl genes from the generated chimp transcripts and stores them
# in the database.
#
###############################################################################


sub store_gene {
  my $db = shift;
  my $hum_gene = shift; # human gene
  my $ctranscripts = shift; # chimp transcripts

  my $MIN_AA_LEN = 15;
  my $MIN_NT_LEN = 600;

  my $analysis = $db->get_AnalysisAdaptor->fetch_by_logic_name('ensembl');

  # Look at the translations and convert any transcripts with stop codons
  # into pseudogenes
  foreach my $ct (@$ctranscripts) {
    if($ct->translation && $ct->translate->seq() =~ /\*/) {
      $ct->translation(undef);
    }
  }


  # Group transcripts by their strand and scaffold.  We
  # cannot really build genes that spand scaffolds or strands
  my (%ctrans_hash, %nt_lens, %aa_lens);

  foreach my $ct (@$ctranscripts) {
    my $region = $ct->slice->seq_region_name() . ':' . $ct->strand();

    $ctrans_hash{$region} ||= [];
    push @{$ctrans_hash{$region}}, $ct;

    # keep track of how many nucleotides and amino acids are in the
    # transcripts from this gene that made it to this area.  If there
    # are not many, the transcript should probably be rejected.
    my $nt_len = length($ct->spliced_seq()) || 0;
    my $aa_len = ($ct->translation()) ? length($ct->translate->seq()) : 0;

    $nt_lens{$region} ||= 0;
    $nt_lens{$region} += $nt_len;

    $aa_lens{$region} ||= 0;
    $aa_lens{$region} += $aa_len;
  }

  my %chimp_genes;

  my $gene_adaptor = $db->get_GeneAdaptor();

  foreach my $region (keys %ctrans_hash) {
    # keep transcripts if there is a minimum amount of nucleotide
    # OR amino acid sequence in transcripts in the same region
    next if($nt_lens{$region}<$MIN_NT_LEN && $aa_lens{$region}<$MIN_AA_LEN);

    # one gene for each region
    my $cgene = $chimp_genes{$region} ||= Bio::EnsEMBL::Gene->new();

    generate_stable_id($cgene);

    # rename transcripts and add to gene
    foreach my $ctrans (@{$ctrans_hash{$region}}) {
      generate_stable_id($ctrans);

      # rename translation
      if($ctrans->translation) {
        generate_stable_id($ctrans->translation);
      }

      $cgene->add_Transcript($ctrans);
    }

    # rename all of the exons
    # but watch out because duplicate exons will be merged and we do not
    # want to generate multiple names
    my %ex_stable_ids;
    foreach my $ex (@{$cgene->get_all_Exons()}) {
      if($ex_stable_ids{$ex->hashkey()}) {
        $ex->stable_id($ex_stable_ids{$ex->hashkey()});
      } else {
        generate_stable_id($ex);
        $ex_stable_ids{$ex->hashkey()} = $ex->stable_id();
      }
    }

    # set the analysis on the gene object
    $cgene->analysis($analysis);


    # for now just grab all HUGO xrefs, and take last one as display xref;
    my $display_xref;
    foreach my $gx (@{$hum_gene->get_all_DBLinks()}) {
      if(uc($gx->dbname()) eq 'HUGO') {
        $cgene->add_DBEntry($gx);
        $display_xref = $gx;
      }
    }

    $cgene->display_xref($display_xref) if($display_xref);

    my $name = $cgene->stable_id();

    $name .= '/'.$display_xref->display_id() if($display_xref);

    $cgene->type('ensembl');

    # store the bloody thing
    print STDERR "Storing gene: $name\n";
    $gene_adaptor->store($cgene);
  }

  return;
}



###############################################################################
# generate_stable_id
#
# Generates a stable_id for a gene, transcript, translation or exon and sets
# it on the object.
#
###############################################################################


my ($TRANSCRIPT_NUM, $GENE_NUM, $EXON_NUM, $TRANSLATION_NUM);


sub generate_stable_id {
  my $object = shift;

  my $SPECIES_PREFIX = 'PTR';
  my $PAD            = 18;

  my $type_prefix;
  my $num;

  if($object->isa('Bio::EnsEMBL::Exon')) {
    $type_prefix = 'E';
    $EXON_NUM       ||= 0;
    $num = ++$EXON_NUM;
  } elsif($object->isa('Bio::EnsEMBL::Transcript')) {
    $type_prefix = 'T';
    $TRANSCRIPT_NUM ||= 0;
    $num = ++$TRANSCRIPT_NUM;
  } elsif($object->isa('Bio::EnsEMBL::Gene')) {
    $type_prefix = 'G';
    $GENE_NUM       ||= 0;
    $num = ++$GENE_NUM;
  } elsif($object->isa('Bio::EnsEMBL::Translation')) {
    $type_prefix = 'P';
    $TRANSLATION_NUM ||= 0;
    $num = ++$TRANSLATION_NUM;
  } else {
    throw('Unknown object type '.ref($object).'. Cannot create stable_id.');
  }

  my $prefix = "ENS${SPECIES_PREFIX}${type_prefix}";

  my $pad = $PAD - length($prefix) - length($num);

  $object->version(1);
  $object->stable_id($prefix . ('0'x$pad) . $num);
}





###############################################################################
# usage
#
###############################################################################

sub usage {
  my $msg = shift;

  print STDERR "$msg\n\n" if($msg);

   print STDERR <<EOF;
usage:   perl human2chimp <options>

options: -hdbname <dbname>      human database name

         -hhost <hostname>      human host name (default localhost)

         -huser <user>          human mysql db user with read priveleges

         -hpass <password>      human mysql user password (default none)

         -hport <port>          human mysql db port (default 3306)

         -hassembly <assembly>  human assembly version (default NCBI34)

         -cdbname <dbname>      chimp database name

         -chost <hostname>      chimp host name (default localhost)

         -cuser <user>          chimp mysql db user with read priveleges

         -cpass <password>      chimp mysql user password (default none)

         -cport <port>          chimp mysql db port (default 3306)

         -cassembly <assembly>  chimp assembly version (default BROAD1)

         -store                 flag indicating genes are to be stored in a
                                destination database

         -ddbname <dbname>      destination database name

         -dhost <hostname>      destination host name (default localhost)

         -duser <user>          destination mysql db user with write priveleges

         -dpass <password>      destination mysql user password (default none)

         -dport <port>          desitnation mysql db port (default 3306)

         -help                  display this message

example: perl human2chimp.pl -hdbname homo_sapiens_core_20_34b -hhost ecs2d \\
                             -huser ensro -cdbname pan_troglodytes_core_20_1 \\
                             -chost ecs4 -cport 3350 -cuser ensro \\
                             -store -ddbname pt_genes -dhost ecs1d \\
                             -duser ensadmin -dpass secret

EOF

  exit;
}




