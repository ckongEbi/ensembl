
#
# BioPerl module for DB/ContigI.pm
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::DB::ContigI.pm - Abstract Interface for Contig

=head1 SYNOPSIS


    # contigs can be made in a number of different ways
    $contig = $obj->get_Contig($contigid);
 
    # contigs objects have an extend method. This gives back
    # a new contig object which is longer to the 5' and 3' end
    # If it runs out of sequence, it truncates silently.
    $virtual_contig = $contig->extend(1000,1000);

    # contigs have special feature extraction functions
    @repeats = $contig->get_all_RepeatFeatures();
    @sim     = $contig->get_all_SimilarityFeatures();

    # you can get genes attached to this contig. This does not
    # mean that all the gene is on this contig, just one exon
    @genes   = $contig->get_all_Genes();

    # ContigI is-a Bio::SeqI which is-a PrimarySeqI. This means
    # that the normal bioperl functions work ok. For example:

    $string = $contig->seq(); # the entire sequence
    $string = $contig->subseq(100,120);  # a sub sequence

    $seqout = Bio::SeqIO->new( '-format' => 'embl', -fh => \*STDOUT );
    $seqout->write_seq($contig);



=head1 DESCRIPTION

The contig interface defines a single continuous piece of DNA with both
features and genes on it. It is-a Bio::SeqI interface, meaning that it
can be used in any function call which takes bioperl Bio::SeqI objects.

It has additional methods, in particular the ability to only get a 
subset of features out and genes.

The contig interface just defines a number of functions which have to provided 
by implementations. Two good implementations are the RawContig implementation
found in Bio::EnsEMBL::DBSQL::RawContig and the generic VirtualContig interface
in Bio::EnsEMBL::Virtual::Contig (previously Bio::EnsEMBL::DB::VirtualContig)


=head1 CONTACT

Ewan Birney, <birney@ebi.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::DB::ContigI;

use vars ('@ISA');
use strict;
use Bio::EnsEMBL::VirtualGene;
use Bio::SeqI;
use Bio::EnsEMBL::Root;

@ISA = qw( Bio::EnsEMBL::Root Bio::SeqI );


=head2 primary_seq

 Title   : seq
 Usage   : $seq = $contig->primary_seq();
 Function: Gets a Bio::PrimarySeqI object out from the contig
 Example :
 Returns : Bio::PrimarySeqI object
 Args    :


=cut

sub primary_seq {
   my ($self) = @_;
   $self->throw("Object did not provide the primary_seq method on a contig interface");
}


=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)


=cut

sub id{
    my ($self) = @_;
    $self->throw("Object did not provide the id method on a contig interface");
}


=head2 internal_id

 Title   : internal_id
 Usage   : $obj->internal_id($newval)
 Function: 
 Example : 
 Returns : value of database internal id
 Args    : newvalue (optional)

=cut

sub internal_id {
   my ($self,$value) = @_;
    $self->throw("Object did not provide the id method on a contig interface");
}

=head2 get_all_SeqFeatures

 Title   : get_all_SeqFeatures
 Usage   : foreach my $sf ( $contig->get_all_SeqFeatures ) 
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_SeqFeatures{
   my ($self) = @_;

   $self->throw("Object did not provide the get_all_SeqFeatures method on Contig interface!");

}



=head2 get_all_SimilarityFeatures_above_score

 Title   : get_all_SimilarityFeatures_above_score
 Usage   : foreach my $sf ( $contig->get_all_SimilarityFeatures_above_score(analysis_type, score) ) 
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_SimilarityFeatures_above_score{
   my ($self) = @_;

   $self->throw("Object did not provide the get_all_SimilarityFeatures_above_score method in ContigI abstract class!");

}




=head2 get_all_SimilarityFeatures

 Title   : get_all_SimilarityFeatures
 Usage   : foreach my $sf ( $contig->get_all_SimilarityFeatures ) 
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_SimilarityFeatures{
   my ($self) = @_;

   $self->throw("Object did not provide the get_all_SimilarityFeatures method on Contig interface!");

}




=head2 get_all_RepeatFeatures

 Title   : get_all_RepeatFeatures
 Usage   : foreach my $sf ( $contig->get_all_RepeatFeatures ) 
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_RepeatFeatures{
   my ($self) = @_;

   $self->throw("Object did not provide the get_all_RepeatFeatures method on Contig interface!");

}




=head2 get_all_ExternalFeatures

 Title   : get_all_ExternalFeatures (Abstract)
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_ExternalFeatures{
   my ($self) = @_;
   
   $self->throw("Abstract method get_all_ExternalFeatures encountered in base class. Implementation failed to complete it")

}

=head2 get_all_ExternalGenes

 Title   : get_all_ExternalGenes (Abstract)
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_ExternalGenes {
   my ($self) = @_;
   
   $self->throw("Abstract method get_all_ExternalGenes encountered in base class. Implementation failed to complete it")

}






=head2 get_all_Genes

 Title   : get_all_Genes
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_Genes{
   my ($self) = @_;

   $self->throw("Object did not provide the get_all_Genes method on Contig interface!");

}






=head2 get_Genes_by_Type

 Title   : get_Genes_by_Type
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_Genes_by_Type{
   my ($self) = @_;

   $self->throw("Object did not provide the get_Genes_by_Type method on Contig interface!");

}


=head2 length

 Title   : length
 Usage   : 
 Function: Provides the length of the contig
 Example :
 Returns : 
 Args    :


=cut

sub length {
   my ($self,@args) = @_;

   $self->throw("Object did not provide the length method on Contig interface!");

}

=head2 extend

 Title   : extend
 Usage   : $newcontig = $contig->extend(1000,-1000)
 Function: Makes a new contig shifted along by the base pairs to the
           5' and the 3'. 
 Example :
 Returns : A ContigI implementing object
 Args    :


=cut

sub extend{
   my ($self,@args) = @_;

   $self->throw("Object did not provide the extend method on Contig interface!");
}

=head2 dbobj

 Title   : dbobj
 Usage   : $obj = $contig->dbobj
 Function: returns a Bio::EnsEMBL::DB::ObjI implementing function
 Example :
 Returns : 
 Args    :


=cut

sub dbobj{
   my ($self,@args) = @_;

   $self->throw("Object did not provide the dbobj method on the Contig interface");
}


=head2 SeqI implementing methods

As ContigI is-a SeqI, we need to implement some sequence
feature methods. It is in these calls where the "magic" happens
by calling VirtualGene for genes to map genes to contigs.

You do not need to implement this methods, but you can if you 
wish to control their behaviour

=cut

=head2 top_SeqFeatures

 Title   : top_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub top_SeqFeatures{
   my ($self,@args) = @_;
   my (@f);
   push(@f,$self->get_all_SeqFeatures());
   foreach my $gene ( $self->get_all_Genes()) {
       my $vg = Bio::EnsEMBL::VirtualGene->new(-gene => $gene,-contig => $self);
       push(@f,$vg);
   }

   return @f;
}



=head2 all_SeqFeatures

 Title   : all_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub all_SeqFeatures {
   my ($self) = @_;
   my (@array);
   foreach my $feat ( $self->top_SeqFeatures() ){
       push(@array,$feat);
       &_retrieve_subSeqFeature(\@array,$feat);
   }

   return @array;
}


sub _retrieve_subSeqFeature {
    my ($arrayref,$feat) = @_;

    foreach my $sub ( $feat->sub_SeqFeature() ) {
	push(@$arrayref,$sub);
	&_retrieve_subSeqFeature($arrayref,$sub);
    }

}

=head2 annotation

 Title   : annotation
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub annotation{
   my ($self,@args) = @_;

   if( $self->can('get_annotation_hook') ) {
       return $self->get_annotation_hook();
   }
   return ();
}


=head2 PrimarySeqI implementing methods

As Bio::SeqI is-a PrimarySeqI, we need to implement these methods.
They can all be delegated to PrimarySeq. You do not need to implement
these methods

=cut

=head2 seq

 Title   : seq
 Usage   : $string = $contig->seq();
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub seq{
   my ($self,@args) = @_;

   return $self->primary_seq->seq();
}

=head2 subseq

 Title   : subseq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub subseq{
   my ($self,$start,$end) = @_;

   return $self->primary_seq->subseq($start,$end);

}

=head2 display_id

 Title   : display_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub display_id{
   my ($self,@args) = @_;

   return $self->id();
}

=head2 primary_id

 Title   : primary_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub primary_id{
   my ($self,@args) = @_;

   return "$self";
}

=head2 accession_number

 Title   : accession_number
 Usage   : $obj->accession_number($newval)
 Function: 
 Returns : value of accession_number
 Args    : newvalue (optional)


=cut

sub accession_number{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'accession_number'} = $value;
    }
    return $obj->{'accession_number'};

}

=head2 desc

 Title   : desc
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub desc{
   my ($self,@args) = @_;

   return "Ensembl Contig";
}


=head1 Decorating methods

These methods do not have to implemented by the derived object.
They are work on top of the interface defined above

=cut



sub get_AnnSeq {
    my $self = shift;
    $self->throw("You should use seq function on the ContigI interface");
}

=head2 write_acedb

 Title   : write_acedb
 Usage   : $contig->write_acedb(\*FILEHANDLE);            
           $contig->write_acedb(\*FILEHANDLE, $ace_seq_name, $type, $supp_evid, $revcom, $url_obj);           
 Function: Dumps exons, transcript and gene objects of a contig in acedb format
 Returns : number of genes dumped
 Args    :  \*FILEHANDLE: file handle where the file is going to be written
            $ace_seq_name: name of the aceDB-clone name
            $type: type of gene in the ensEMBL database (default is 'ensembl')
            $supp_evid: supporting evidences (optional)
            $revcom: set to 1, if sequence coordinates for the complementary strand are needed in the ace file (optional)
            $url_ob: Transcript AceDB URL object (optional)
=cut

sub write_acedb {
    my ($self, $fh, $seqname, $type, $supp_evid, $revcom, $url_ob) = @_;
    
    my $nexons=0; 
    my $contig_id = $self->id();
     
    $type ||= 'ensembl';
    $supp_evid ||= 0;    
    $seqname ||= $contig_id;
    
    
    # get all genes 
    my @genes = $self->get_Genes_by_Type( $type );
    
    # exit if the clone has no genes
    unless (@genes) {                
        print STDERR "'$seqname' has no genes\n";
        return $nexons;
    } 
    
    GENE:          
    foreach my $gene ( @genes ){
        my $gene_id = $gene->stable_id;
	$gene_id = $gene->dbID unless $gene_id;
        	
	# get all the transcripts of this gene. 
        my @trans_in_gene = $gene->each_Transcript;
        
        # get another gene if this one has no transcripts (pseudogene)
        unless (@trans_in_gene ) {
            print STDERR "'$seqname' contains a gene with no transcripts (gene_id: '$gene_id')\n";
            next GENE;
        }
        
        # for each transcript
        TRANSCRIPT:
        foreach my $trans ( @trans_in_gene ) {
            my $trans_id = $trans->stable_id;
	    $trans_id = $trans->dbID unless $trans_id;
            my $description = $trans->description;
            
            # get all exons of this transcript	                           
            my @exons = $trans->get_all_Exons;

            # get transcript exons which belong to the contig 
            my @exons_in_contig;
            
            foreach my $exon ( @exons ) {
		if ( $exon->contig_id eq $contig_id ) {
		    push ( @exons_in_contig, $exon );
		    $nexons++;
		}
            }
            
            if (@exons_in_contig) {
                my $tstart;
                my $tend;
                my $ace_tstart;
                my $ace_tend;
                my $tstrand = $exons_in_contig[0]->strand;
                
                # check the strand and get the coordinates
                if( $tstrand == 1 ) {
                    $tstart = $exons_in_contig[0]->start;
                    $tend   = $exons_in_contig[$#exons_in_contig]->end;
                } else {
                    $tstart = $exons_in_contig[0]->end;
                    $tend   = $exons_in_contig[$#exons_in_contig]->start;
                }
                
                unless ($revcom){
                    $ace_tstart = $tstart;
                    $ace_tend = $tend;
                }else{
                    # remaping transcript coordinates in the complementary strand 
                    my $contig_length = $self->length;
                    $ace_tstart = $contig_length - $tstart;
                    $ace_tend = $contig_length - $tend;
                }

	        # start .ace file printing...
	        # print coordinates of the transcript relative to the contig
	        print $fh "Sequence $seqname\n";
	        print $fh "Subsequence $trans_id $ace_tstart $ace_tend\n\n";

                # print coordinates of each exon relative to the transcript   
	        print $fh "Sequence $trans_id\nSource $seqname\n";
                print $fh "CDS\nCDS_predicted_by EnsEMBL\nMethod EnsEMBL\n";
                foreach my $exon ( @exons_in_contig ) {
                    if( $tstrand == 1 ) {
                        print $fh "Source_Exons ", ($exon->start - $tstart + 1),
                                    " ",($exon->end - $tstart +1), "\n";
                    } else {
                        print $fh "Source_Exons ", ($tstart - $exon->end +1 ),
                                    " ",($tstart - $exon->start+1), "\n";
                    }                      
                }
                
                # indicate end or start not found for transcript across several contigs
                if ($exons[0] != $exons_in_contig[0]) {
                    print $fh "Start_not_found\n";
                } 
                if ($exons[$#exons] != $exons_in_contig[$#exons_in_contig]) {
                    print $fh "End_not_found\n";
                }     
                if ($url_ob){
                    # URL object tag  
                    print $fh "Web_location $url_ob\n";
                }
                if ($description) {
                    print $fh qq{Remark "$description"\n};
                }
	        print $fh "\n\n";

            } else {
                print STDERR "'$trans_id' has no exons in '$seqname'\n";
                next TRANSCRIPT;
            }
        }
    }
    return $nexons;
}


=head2 as_seqfeatures

 Title   : as_seqfeatures
 Usage   : @seqfeatures = $contig->as_seqfeatures();
           foreach $sf ( @seqfeatures ) { 
	       print $sf->gff_string(), "\n";
           }
 Function: Makes ensembl exons as an array of seqfeature::generic
           objects that can be dumped with the correct additional tags
           about transcripts/genes etc added to them
 Returns : An array of SeqFeature::Generic objects
 Args    :

=cut

sub as_seqfeatures {
    my ($self) = @_;
    my $contig_id=$self->id();
    my @sf;

    # build objects for each exon in each gene
    foreach my $gene ($self->get_all_Genes()){
	my $gene_id=$gene->id;
	foreach my $trans ( $gene->each_Transcript ) {
	    my $transcript_id=$trans->id;
	    foreach my $exon ( $trans->each_Exon ) {
		my $sf= Bio::SeqFeature::Generic->new();
		$sf->seqname($contig_id);
		$sf->source_tag('ensembl');
		$sf->primary_tag('exon');
		$sf->start($exon->start);
		$sf->end($exon->end);
		$sf->strand($exon->strand);
		#$sf->frame($exon->frame);
		$sf->add_tag_value('ensembl_exon_id',$exon->id);
		$sf->add_tag_value('ensembl_transcript_id',$transcript_id);
		$sf->add_tag_value('ensembl_gene_id',$gene_id);
		$sf->add_tag_value('contig_id',$contig_id);
		push(@sf,$sf);
	    }
	}
    }

    # add objects for each feature on contig
    push(@sf,$self->get_all_SeqFeatures);

    return @sf;
}

=head2 embl_order

 Title   : embl_order
 Usage   : $obj->embl_order
 Function: 
 Returns : 
 Args    : 


=cut

sub embl_order{
    my ($self) = @_;
    $self->throw("Object did not provide the embl_order method on a contig interface");
}

=head2 embl_offset

 Title   : embl_offset
 Usage   : $obj->embl_offset
 Function: 
 Returns : 
 Args    : 


=cut

sub embl_offset{
    my ($self) = @_;
    $self->throw("Object did not provide the embl_offset method on a contig interface");
}

=head2 seq_date

 Title   : seq_date
 Usage   : $contig->seq_date()
 Function: Gives the unix time value of the dna table 
           created datetime field, which indicates
           the original time of the dna sequence data
 Example : $contig->seq_date()
 Returns : unix time
 Args    : none


=cut

sub seq_date{
    my ($self) = @_;
    $self->throw("Object did not provide the seq_date method on a contig interface");
}

=head2 version

 Title   : version
 Usage   : $obj->version($newval)
 Function: 
 Returns : value of version
 Args    : newvalue (optional)


=cut

sub version{
   my $self = shift;
    $self->throw("Object did not provide the version method on a contig interface");

}

=head1 Cruft

Not clear if this method belongs here....

=cut

#
# Not sure where to put this?
#
 
=head2 find_supporting_evidence

 Title   : find_supporting_evidence
 Usage   : $obj->find_supporting_evidence($exon);
 Function: Looks through all the similarity features and
           stores as supporting evidence any feature
           that overlaps with an exon.  I know it is
           a little crude but it\'s a start/
 Example : 
 Returns : Nothing
 Args    : Bio::EnsEMBL::Exon


=cut


sub find_supporting_evidence {
    my ($self,$exon) = @_;

    my @features = $self->get_all_SimilarityFeatures;

    foreach my $f (@features) {
	if ($f->overlaps($exon)) {
	    $exon->add_Supporting_Feature($f);
	}
    }
}

=head2 get_repeatmasked_seq

 Title	 : get_repeatmasked_seq
 Usage	 : $seq = $obj->get_repeatmasked_seq()
 Function: Masks DNA sequence by replacing repeats with N\'s
 Returns : Bio::PrimarySeq
 Args	 : none


=cut


sub get_repeatmasked_seq {
    my ($self) = @_;
    my @repeats = $self->get_all_RepeatFeatures();
    my $seq = $self->primary_seq();
    my $dna = $seq->seq();
    my $masked_dna = $self->mask_features($dna, @repeats);
    my $masked_seq = Bio::PrimarySeq->new(   '-seq'        => $masked_dna,
                                             '-display_id' => $self->id,
                                             '-primary_id' => $self->id,
                                             '-moltype' => 'dna',
					     );
    return $masked_seq;
}


sub mask_features {
    my ($self, $dnastr,@repeats) = @_;
    my $dnalen = CORE::length($dnastr);
    
  REP:foreach my $f (@repeats) {
      
      my $start    = $f->start;
      my $end	   = $f->end;
      my $length = ($end - $start) + 1;
      
      if ($start < 0 || $start > $dnalen || $end < 0 || $end > $dnalen) {
	  print STDERR "Eeek! Coordinate mismatch - $start or $end not within $dnalen\n";
	  next REP;
      }
      
      $start--;
      
      my $padstr = 'N' x $length;
      
      substr ($dnastr,$start,$length) = $padstr;
  }
    return $dnastr;
}                                       # mask_features


=head2 get_all_PredictionFeatures_as_Transcripts

 Title   : get_all_PredictionFeatures_as_Transcripts
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut
    


sub get_all_PredictionFeatures_as_Transcripts {
    my ($self) = @_;
	
    my @transcripts;
	
    foreach my $ft ($self->get_all_PredictionFeatures())
    {
	
	push @transcripts,&Bio::EnsEMBL::TranscriptFactory::fset2transcript($ft,$self);
	    
    }

    return @transcripts;		
}

=head2 get_gc_content

 Title   : get_gc_content
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub get_gc_content {
   my ($self) = @_;

   my $seq = $self->primary_seq->seq();

   my $num_g = $seq =~ tr/G/G/;
   my $num_c = $seq =~ tr/C/C/;
   #my $num_n = $seq =~ tr/N/N/;

   my $seq_length = $self->primary_seq->length;

   #my $perc_gc = ((($num_g+$num_c)/($seq_length-$num_n))*100);
   my $perc_gc = ((($num_g+$num_c)/($seq_length))*100);
   

   $perc_gc = int($perc_gc+0.5);
   return $perc_gc;
}   

    

1;

