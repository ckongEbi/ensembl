

#
# BioPerl module for Bio::EnsEMBL::DBSQL::DnaAlignFeatureAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::DBSQL::DnaAlignFeatureAdaptor - Adaptor for DnaAlignFeatures

=head1 SYNOPSIS

    $pfadp = $dbadaptor->get_DnaAlignFeatureAdaptor();

    my @feature_array = $pfadp->fetch_by_contig_id($contig_numeric_id);

    my @feature_array = $pfadp->fetch_by_assembly_location($start,$end,$chr,'UCSC');
 
    $pfadp->store($contig_numeric_id,@feature_array);


=head1 DESCRIPTION


This is an adaptor for DNA features on DNA sequence. Like other
feature getting adaptors it has a number of fetch_ functions and a
store function.


=head1 AUTHOR - Ewan Birney

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::DBSQL::DnaAlignFeatureAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::EnsEMBL::Root

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::FeatureFactory;
use Bio::EnsEMBL::DnaDnaAlignFeature;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);
# new() can be inherited from Bio::EnsEMBL::Root


=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Function:
 Returns : 
 Args    :


=cut

sub fetch_by_dbID{
   my ($self,$id) = @_;

   if( !defined $id ) {
       $self->throw("fetch_by_dbID must have an id");
   }

   my $sth = $self->prepare("select p.contig_id,p.contig_start,p.contig_end,p.contig_strand,p.hit_start,p.hit_end,p.hit_strand,p.hit_name,p.cigar_line,p.analysis_id, p.score from dna_align_feature p where p.dna_align_feature_id = $id");
   $sth->execute();

   my ($contig_id,$start,$end,$strand,$hstart,$hend,$hstrand,$hname,$cigar,$analysis_id, $score) = $sth->fetchrow_array();

   if( !defined $contig_id ) {
       $self->throw("No simple feature with id $id");
   }

   my $contig = $self->db->get_RawContigAdaptor->fetch_by_dbID($contig_id);
   my $analysis = $self->db->get_AnalysisAdaptor->fetch_by_dbID($analysis_id);
   my $out= $self->_new_feature($start,$end,$strand,$score,$hstart,$hend,$hstrand,$hname,$cigar,$analysis,$contig->name,$contig->seq);

   return $out;

}

=head2 fetch_by_contig_id

 Title   : fetch_by_contig_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_contig_id{
   my ($self,$cid) = @_;

   if( !defined $cid ) {
       $self->throw("fetch_by_contig_id must have an contig id");
   }

   my $sth = $self->prepare("select p.contig_id,p.contig_start,p.contig_end,p.contig_strand,p.hit_start,p.hit_end,p.hit_strand,p.hit_name,p.cigar_line,p.analysis_id, p.score from dna_align_feature p where p.contig_id = $cid");
   $sth->execute();

   my ($contig_id,$start,$end,$strand,$hstart,$hend,$hstrand,$hname,$cigar,$analysis_id, $score);

   $sth->bind_columns(undef,\$contig_id,\$start,\$end,\$strand,\$hstart,\$hend,\$hstrand,\$hname,\$cigar,\$analysis_id, \$score);

   my @f;
   my $contig = $self->db->get_RawContigAdaptor->fetch_by_dbID($cid);
   my %ana;

   while( $sth->fetch ) {
       if( !defined $ana{$analysis_id} ) {
	   $ana{$analysis_id} = $self->db->get_AnalysisAdaptor->fetch_by_dbID($analysis_id);
       }


       my $out= $self->_new_feature($start,$end,$strand,$score,$hstart,$hend,$hstrand,$hname,$cigar,$ana{$analysis_id},$contig->name,$contig->seq);

       push(@f,$out);
   }
   return @f;
}



sub fetch_by_Slice_and_score {
  my ($self,$slice,$score) = @_;

  return $self->fetch_by_assembly_location_constraint($slice->chr_start,$slice->chr_end,$slice->chr_name,$slice->assembly_type," p.score > $score");
}  


=head2 fetch_by_assembly_location

 Title   : fetch_by_assembly_location
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_assembly_location{
  my ($self,$start,$end,$chr,$type) = @_;
  
  if( !defined $type ) {
    $self->throw("Assembly location must be start,end,chr,type");
  }

  return $self->fetch_by_assembly_location_constraint($start,$end,$chr,$type,undef);
}


=head2 fetch_by_assembly_location_constraint

 Title   : fetch_by_assembly_location_constraint
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_assembly_location_constraint{
  my ($self,$start,$end,$chr,$type,$constraint) = @_;
  
  if( !defined $type ) {
    $self->throw("Assembly location must be start,end,chr,type");
  }

  if( $start !~ /^\d/ || $end !~ /^\d/ ) {
    $self->throw("start/end must be numbers not $start,$end (have you typed the location in the right way around - start,end,chromosome,type)?");
  }
  
  my $mapper = $self->db->get_AssemblyMapperAdaptor->fetch_by_type($type);
  
  $mapper->register_region($chr,$start,$end);

  my @cids = $mapper->list_contig_ids($chr, $start ,$end);
  
  # build the SQL
  

  #print STDERR "have @cids contig ids\n";

  if( scalar(@cids) == 0 ) {
    return ();
  }

  my $cid_list = join(',',@cids);

  my $sql = "select p.contig_id,p.contig_start,p.contig_end,p.contig_strand,p.hit_start,p.hit_end,p.hit_strand,p.hit_name,p.cigar_line,p.analysis_id,p.score from dna_align_feature p where p.contig_id in ($cid_list)";
  
  if( defined $constraint ) {
    $sql .=  " AND $constraint";
  }
  #print STDERR "SQL $sql\n";

  my $sth = $self->prepare($sql);

  $sth->execute();
  
  
  my ($contig_id,$start,$end,$strand,$hstart,$hend,$hstrand,$hname,$cigar,$analysis_id, $score);
  
  $sth->bind_columns(undef,\$contig_id,\$start,\$end,\$strand,\$hstart,\$hend,\$hstrand, \$hname,\$cigar,\$analysis_id, \$score);
  

  my @f;
  my %ana;
  my $counter = 0;
  while( $sth->fetch ) {
    # we whether this is sensible to use or not
    
    my @coord_list = $mapper->map_coordinates_to_assembly($contig_id, $start,$end,$strand,"rawcontig");
       
    # coord list > 1 - means does not cleanly map. At the moment, skip
    if( scalar(@coord_list) > 1 ) {
      next;
    }
    
    if( !defined $ana{$analysis_id} ) {
      $ana{$analysis_id} = $self->db->get_AnalysisAdaptor->fetch_by_dbID($analysis_id);
    }

    # ok, ready to build a sequence feature: do we want this relative or not?

  
    my $out= $self->_new_feature($start,$end,$strand,$score,$hstart,$hend,$hstrand,$hname,$cigar,$ana{$analysis_id},"slice",undef);

    push(@f,$out);
  }
  #print STDERR "have ".$counter." gaps\n";
  return @f;

}

=head2 store

 Title   : store
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub store{
   my ($self,$contig_id,@sf) = @_;

   if( scalar(@sf) == 0 ) {
       $self->throw("Must call store with contig_id then sequence features");
   }

   if( $contig_id !~ /^\d+$/ ) {
       $self->throw("Contig_id must be a number, not [$contig_id]");
   }

   my $sth = $self->prepare("insert into dna_align_feature (contig_id,contig_start,contig_end,contig_strand,hit_start,hit_end,hit_strand,hit_name,cigar_line,analysis_id,score,evalue, perc_ident) values (?,?,?,?,?,?,?,?,?,?,?, ?, ?)");

   foreach my $sf ( @sf ) {
       if( !ref $sf || !$sf->isa("Bio::EnsEMBL::DnaDnaAlignFeature") ) {
	   $self->throw("Simple feature must be an Ensembl DnaDnaAlignFeature, not a [$sf]");
       }

       if( !defined $sf->analysis ) {
	   $self->throw("Cannot store sequence features without analysis");
       }
       if( !defined $sf->analysis->dbID ) {
	   # maybe we should throw here. Shouldn't we always have an analysis from the database?
	   $self->throw("I think we should always have an analysis object which has originated from the database. No dbID, not putting in!");
       }
       #print STDERR "storing ".$sf->gffstring."\n";
       $sth->execute($contig_id,$sf->start,$sf->end,$sf->strand,$sf->hstart,$sf->hend,$sf->hstrand,$sf->hseqname,$sf->cigar_string,$sf->analysis->dbID,$sf->score, $sf->p_value, $sf->percent_id);
   }


}

=head2 Internal functions

Internal functions to the adaptor which you never need to call

=cut


sub _new_feature {
  my ($self,$start,$end,$strand,$score,$hstart,$hend,$hstrand,$hseqname,$cigar,$analysis,$seqname,$seq) = @_;

  if( !defined $seqname ) {
    $self->throw("Internal error - wrong number of arguments to new_feature");
  }

  my $f1 = Bio::EnsEMBL::SeqFeature->new();
  my $f2 = Bio::EnsEMBL::SeqFeature->new();

  $f1->start($start);
  $f1->end($end);
  $f1->strand($strand);
  $f1->score($score);
  $f1->seqname($seqname);
  if( defined $seq ) {
    $f1->attach_seq($seq);
  }

  $f2->start($hstart);
  $f2->end($hend);
  $f2->strand($hstrand);
  $f2->seqname($hseqname);

  $f1->analysis($analysis);
  $f2->analysis($analysis);


  my $out = Bio::EnsEMBL::DnaDnaAlignFeature->new( -cigar_string => $cigar, -feature1 => $f1, -feature2 => $f2);

  return $out;
}
    
1;


