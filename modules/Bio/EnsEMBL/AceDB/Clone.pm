
#
# BioPerl module for DB::Clone
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::AceDB::Clone - Object representing one clone

=head1 SYNOPSIS

    # $db is Bio::EnsEMBL::AceDB::Obj 

    $clone = $db->get_Clone();

    @contig = $clone->get_Contigs();

    @genes  = $clone->get_all_Genes();

=head1 DESCRIPTION

Represents information on one Clone

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::AceDB::Clone;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;

@ISA = qw(Bio::EnsEMBL::DB::CloneI Bio::Root::RootI);
# new() is inherited from Bio::Root::Object

# _initialize is where the heavy stuff will happen when new is called

sub new {
    my($pkg,@args) = @_;

    my $self = bless {}, $pkg;

    # set stuff in self from @args
    my ($dbobj,$id) = $self->_rearrange([qw(DBOBJ
					    ID
					    )],@args);

    $id || $self->throw("Cannot make contig db object without id");
    $dbobj || $self->throw("Cannot make contig db object without db object");
    $dbobj->isa('Bio::EnsEMBL::AceDB::Obj') || 
        $self->throw("Cannot make contig db object with a $dbobj object");

    $self->id($id);
    $self->_dbobj($dbobj);

    return $self; # success - we hope!
}


=head2 seq

 Title   : seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub seq {
   my ($self) = @_;

   my ($contig) = $self->get_Contig($self->id());
   return $contig->seq();
}



=head2 embl_version

 Title   : embl_version
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub embl_version {
   my ($self) = @_;
   my ($contig) = $self->get_Contig($self->id());
   if (my $version = $contig->ace_seq->at('DB_info.Sequence_version[1]')) {
        return $version->name;
   }
   return;
}


=head2 embl_id

 Title   : embl_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub embl_id {
   my ($self) = @_;

   my ($contig) = $self->get_Contig($self->id());
   if (my $database = $contig->ace_seq->at('DB_info.Database[1]')) {

        if ($database eq "EMBL") {
            if (my $embl_id = $contig->ace_seq->at('DB_info.Database[2]')) {
          
                return $embl_id->name;
            }
        }       
   }

   return $self->id;

}


=head2 htg_phase

 Title   : htg_phase
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)

=cut

sub htg_phase {
   my ($obj) = @_;
    return 3;
}


=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)

=cut

sub id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_clone_id'} = $value;
    }
    return $obj->{'_clone_id'};

}

=head2 created

 Title   : created
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub created {
    my ($self) = @_;
    
    return $self->get_Contig->seq_date;
}


=head2 modified

 Title   : modified
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub modified {
    my ($self) = @_;
    
    return $self->get_Contig->seq_date;
}


=head2 seq_date

 Title   : seq_date
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub seq_date {
    my ($self) = @_;
    
    return $self->get_Contig->seq_date;
}


=head2 sv

 Title   : sv
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub sv {
    my ($self) = @_;
    return 1;  
}


=head2 version

 Title   : version
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub version {
   my ($self) = @_;
 
   my ($contig) = $self->get_Contig($self->id()); 
   if (my $version = $contig->ace_seq->at('DB_info.Sequence_version[1]')) {   
        return $version->name;
   }
   # If the version isn't defined just return 1.
   return 1;
}


=head2 get_all_Contigs

 Title   : get_Contigs
 Usage   : foreach $contig ( $clone->get_Contigs ) 
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub get_all_Contigs {
    my ($self) = @_;
                                           
    return ($self->get_Contig($self->id));
}


=head2 get_all_ContigOverlaps 

 Title   : get_all_ContigOverlaps
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_all_ContigOverlaps {
    my ($self) = @_;
    
    return $self->get_Contig->get_all_ContigOverlaps;
}


=head2 get_Contig

 Title   : get_Contig
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub get_Contig {
    my ($self,$contigid) = @_;

    if( defined($contigid) and $contigid ne $self->id() ) {
        $self->throw("In an Acedb database, trying to get a contigid $contigid not on the clone. Indicates an error!");
    }
    
    unless ($self->{'_contig_cache'}) {
        my $contig = new Bio::EnsEMBL::AceDB::Contig(
            '-dbobj'  => $self->_dbobj,
            '-id'     => $self->id,
            );
        $self->{'_contig_cache'} = $contig;
    }

    return $self->{'_contig_cache'};
}


=head2 get_all_Genes

 Title   : get_all_Genes
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub get_all_Genes {
   my ($self,@args) = @_;
   my (@genes);

   foreach my $contig ( $self->get_all_Contigs ) {
       push(@genes,$contig->get_all_Genes());
   }
   return @genes;
}


=head2 _dbobj

 Title   : _dbobj
 Usage   : $obj->_dbobj($newval)
 Function: 
 Example : 
 Returns : value of _dbobj
 Args    : newvalue (optional)

=cut

sub _dbobj {
    my ($obj,$value) = @_;
    if( defined $value) {
        $obj->{'_dbobj'} = $value;
    }
    return $obj->{'_dbobj'};

}

1;
