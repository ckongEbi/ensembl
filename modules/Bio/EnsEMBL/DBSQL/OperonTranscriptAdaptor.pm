
=head1 LICENSE

  Copyright (c) 1999-2011 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

=head1 NAME

Bio::EnsEMBL::DBSQL::OperonAdaptor - Database adaptor for the retrieval and
storage of OperonTranscript objects

=head1 SYNOPSIS


my $operon_transcript_adaptor =  Bio::EnsEMBL::DBSQL::OperonTranscriptAdaptor->new($dba);
$operon_transcript_adaptor->store($operon_transcript);
my $operon_transcript2 = $operon_transcript_adaptor->fetch_by_dbID( $operon->dbID() );
my $operon_transcripts = $operon_transcript_adaptor->fetch_all_by_gene( $gene );

=head1 DESCRIPTION

This is a database aware adaptor for the retrieval and storage of operon
transcript objects.

=head1 METHODS

=cut

package Bio::EnsEMBL::DBSQL::OperonTranscriptAdaptor;

use strict;

use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning );
use Bio::EnsEMBL::Utils::Scalar qw( assert_ref );
use Bio::EnsEMBL::DBSQL::SliceAdaptor;
use Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Operon;
use Bio::EnsEMBL::OperonTranscript;
use Bio::EnsEMBL::Utils::SqlHelper;

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor);

# _tables
#  Arg [1]    : none
#  Description: PROTECTED implementation of superclass abstract method.
#               Returns the names, aliases of the tables to use for queries.
#  Returntype : list of listrefs of strings
#  Exceptions : none
#  Caller     : interna
#  Status     : Stable

sub _tables {
	return ( [ 'operon_transcript', 'o' ],
			 [ 'operon_transcript_stable_id', 'osi' ] );
}

# _columns
#  Arg [1]    : none
#  Example    : none
#  Description: PROTECTED implementation of superclass abstract method.
#               Returns a list of columns to use for queries.
#  Returntype : list of strings
#  Exceptions : none
#  Caller     : internal
#  Status     : Stable

sub _columns {
	my ($self) = @_;

	my $created_date =
	  $self->db()->dbc()->from_date_to_seconds("osi.created_date");
	my $modified_date =
	  $self->db()->dbc()->from_date_to_seconds("osi.modified_date");

	return ( 'o.operon_transcript_id', 'o.seq_region_id',
			 'o.seq_region_start',     'o.seq_region_end',
			 'o.seq_region_strand',    'o.display_label',
			 'osi.stable_id',          'osi.version',
			 $created_date,            $modified_date );
}

sub _left_join {
	return ( [ 'operon_transcript_stable_id',
			   "osi.operon_transcript_id = o.operon_transcript_id" ] );
}

=head2 list_dbIDs

  Example    : @ot_ids = @{$ot_adaptor->list_dbIDs()};
  Description: Gets an array of internal ids for all operon_transcripts in the current db
  Arg[1]     : <optional> int. not 0 for the ids to be sorted by the seq_region.
  Returntype : Listref of Ints
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub list_dbIDs {
	my ( $self, $ordered ) = @_;

	return $self->_list_dbIDs( "operon", undef, $ordered );
}

=head2 list_stable_ids

  Example    : @stable_ot_ids = @{$ot_adaptor->list_stable_ids()};
  Description: Gets an listref of stable ids for all operon_transcripts in the current db
  Returntype : reference to a list of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub list_stable_ids {
	my ($self) = @_;

	return $self->_list_dbIDs( "operon_stable_id", "stable_id" );
}

sub list_seq_region_ids {
	my $self = shift;

	return $self->_list_seq_region_ids('operon');
}

=head2 fetch_by_stable_id

  Arg [1]    : String $id 
               The stable ID of the operon_transcript to retrieve
  Example    : $operon_transcript = $operon_transcript_adaptor->fetch_by_stable_id('ENSG00000148944');
  Description: Retrieves a operon_transcript object from the database via its stable id.
               The operon_transcript will be retrieved in its native coordinate system (i.e.
               in the coordinate system it is stored in the database). It may
               be converted to a different coordinate system through a call to
               transform() or transfer(). If the operon_transcript or exon is not found
               undef is returned instead.
  Returntype : Bio::EnsEMBL::OperonTranscript or undef
  Exceptions : if we cant get the operon_transcript in given coord system
  Caller     : general
  Status     : Stable

=cut

sub fetch_by_stable_id {
	my ( $self, $stable_id ) = @_;

	my $constraint = "osi.stable_id = ? AND o.is_current = 1";
	$self->bind_param_generic_fetch( $stable_id, SQL_VARCHAR );
	my ($operon_transcript) = @{ $self->generic_fetch($constraint) };

	return $operon_transcript;
}

=head2 fetch_by_name

  Arg [1]    : String $label - name of operon transcript to fetch
  Example    : my $operon_transcript = $operonAdaptor->fetch_by_name("ECK0012121342");
  Description: Returns the operon transcript which has the given display label or undef if
               there is none. If there are more than 1, only the first is
               reported.
  Returntype : Bio::EnsEMBL::OperonTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_by_name {
	my $self  = shift;
	my $label = shift;

	my $constraint = "o.display_label = ?";
	$self->bind_param_generic_fetch( $label, SQL_VARCHAR );
	my ($operon) = @{ $self->generic_fetch($constraint) };

	return $operon;
}
=head2 fetch_all

  Example     : $operon_transcripts = $operon_adaptor->fetch_all();
  Description : Retrieves all operon transcripts stored in the database.
  Returntype  : listref of Bio::EnsEMBL::OperonTranscript
  Caller      : general
  Status      : At Risk

=cut
sub fetch_all {
	my ($self) = @_;

	my $constraint         = '';
	my @operon_transcripts = @{ $self->generic_fetch($constraint) };
	return \@operon_transcripts;
}

=head2 fetch_all_versions_by_stable_id 

  Arg [1]     : String $stable_id 
                The stable ID of the operon_transcript to retrieve
  Example     : $operon_transcript = $operon_transcript_adaptor->fetch_all_versions_by_stable_id
                  ('ENSG00000148944');
  Description : Similar to fetch_by_stable_id, but retrieves all versions of a
                operon_transcript stored in the database.
  Returntype  : listref of Bio::EnsEMBL::OperonTranscript
  Exceptions  : if we cant get the operon_transcript in given coord system
  Caller      : general
  Status      : At Risk

=cut

sub fetch_all_versions_by_stable_id {
	my ( $self, $stable_id ) = @_;

	my $constraint = "osi.stable_id = ?";
	$self->bind_param_generic_fetch( $stable_id, SQL_VARCHAR );
	return $self->generic_fetch($constraint);
}

=head2 fetch_all_by_Slice

  Arg [1]    : Bio::EnsEMBL::Slice $slice
               The slice to fetch operon_transcripts on.
  Arg [2]    : (optional) string $logic_name
               the logic name of the type of features to obtain
  Arg [3]    : (optional) boolean $load_transcripts
               if true, transcripts will be loaded immediately rather than
               lazy loaded later.
  Arg [4]    : (optional) string $source
               the source name of the features to obtain.
  Arg [5]    : (optional) string biotype
                the biotype of the features to obtain.
  Example    : @operon_transcripts = @{$operon_transcript_adaptor->fetch_all_by_Slice()};
  Description: Overrides superclass method to optionally load transcripts
               immediately rather than lazy-loading them later.  This
               is more efficient when there are a lot of operon_transcripts whose
               transcripts are going to be used.
  Returntype : reference to list of operon_transcripts 
  Exceptions : thrown if exon cannot be placed on transcript slice
  Caller     : Slice::get_all_OperonTranscripts
  Status     : Stable

=cut

sub fetch_all_by_Slice {
	my ( $self, $slice, $logic_name, $load_transcripts ) = @_;

	my $constraint = '';

	my $operons =
	  $self->SUPER::fetch_all_by_Slice_constraint( $slice, $constraint,
												   $logic_name );

	# If there are less than two operons, still do lazy-loading.
	if ( !$load_transcripts || @$operons < 2 ) {
		return $operons;
	}

	# Preload all of the transcripts now, instead of lazy loading later,
	# faster than one query per transcript.

	# First check if transcripts are already preloaded.
	# FIXME: Should check all transcripts.
	if ( exists( $operons->[0]->{'_operon_transcript_array'} ) ) {
		return $operons;
	}

	# Get extent of region spanned by transcripts.
	my ( $min_start, $max_end );
	foreach my $o (@$operons) {
		if ( !defined($min_start) || $o->seq_region_start() < $min_start ) {
			$min_start = $o->seq_region_start();
		}
		if ( !defined($max_end) || $o->seq_region_end() > $max_end ) {
			$max_end = $o->seq_region_end();
		}
	}

	my $ext_slice;

	if ( $min_start >= $slice->start() && $max_end <= $slice->end() ) {
		$ext_slice = $slice;
	} else {
		my $sa = $self->db()->get_SliceAdaptor();
		$ext_slice =
		  $sa->fetch_by_region( $slice->coord_system->name(),
								$slice->seq_region_name(),
								$min_start,
								$max_end,
								$slice->strand(),
								$slice->coord_system->version() );
	}

	# Associate transcript identifiers with operon_transcripts.

	my %o_hash = map { $_->dbID => $_ } @{$operons};

	my $o_id_str = join( ',', keys(%o_hash) );

	my $sth =
	  $self->prepare(   "SELECT operon_id, operon_transcript_id "
					  . "FROM   operon_transcript "
					  . "WHERE  operon_id IN ($o_id_str)" );

	$sth->execute();

	my ( $o_id, $tr_id );
	$sth->bind_columns( \( $o_id, $tr_id ) );

	my %tr_o_hash;

	while ( $sth->fetch() ) {
		$tr_o_hash{$tr_id} = $o_hash{$o_id};
	}

	my $ta = $self->db()->get_OperonTranscriptAdaptor();
	my $transcripts =
	  $ta->fetch_all_by_Slice( $ext_slice,
							   1, undef,
							   sprintf( "ot.operon_transcript_id IN (%s)",
										join( ',',
											  sort { $a <=> $b }
												keys(%tr_o_hash) ) ) );

# Move transcripts onto operon_transcript slice, and add them to operon_transcripts.
	foreach my $tr ( @{$transcripts} ) {
		if ( !exists( $tr_o_hash{ $tr->dbID() } ) ) { next }

		my $new_tr;
		if ( $slice != $ext_slice ) {
			$new_tr = $tr->transfer($slice);
			if ( !defined($new_tr) ) {
				throw("Unexpected. "
					. "Transcript could not be transfered onto OperonTranscript slice."
				);
			}
		} else {
			$new_tr = $tr;
		}

		$tr_o_hash{ $tr->dbID() }->add_OperonTranscript($new_tr);
	}

	return $operons;
} ## end sub fetch_all_by_Slice

=head2 fetch_by_Operon

  Arg [1]    : Bio::EnsEMBL::Operon
  Example    : $ot = $ot_adaptor->fetch_by_Operon($operon);
  Description: Retrieves all operon transcripts belonging to an operon
  Returntype : arrayref of Bio::EnsEMBL::OperonTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_all_by_Operon {
	my ( $self, $operon ) = @_;
	return $self->fetch_by_operon_id( $operon->dbID() );
}

=head2 fetch_by_operon_id

  Arg [1]    : Int id
  Example    : $ot = $ot_adaptor->fetch_by_operon_transcript($operon);
  Description: Retrieves all operon transcripts belonging to an operon
  Returntype : arrayref of Bio::EnsEMBL::OperonTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_by_operon_id {
	my ( $self, $operon_id ) = @_;

	my $constraint = "o.operon_id = ?";
	$self->bind_param_generic_fetch( $operon_id, SQL_INTEGER );
	return $self->generic_fetch($constraint);
}

=head2 fetch_genes_by_operon_transcript

  Arg [1]    : Bio::EnsEMBL::OperonTranscript
  Example    : $ot = $ot_adaptor->fetch_genes_by_operon_transcript($operon_transcript);
  Description: Retrieves all genes attached to an operon transcript
  Returntype : arrayref of Bio::EnsEMBL::Gene
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_genes_by_operon_transcript {
	my ( $self, $operon_transcript ) = @_;
	assert_ref( $operon_transcript, 'Bio::EnsEMBL::OperonTranscript' );
	return $self->fetch_genes_by_operon_transcript_id(
												   $operon_transcript->dbID() );
}

=head2 fetch_genes_by_operon_transcript_id

  Arg [1]    : Int id
  Example    : $ot = $ot_adaptor->fetch_genes_by_operon_transcript($operon_transcript_id);
  Description: Retrieves all genes attached to an operon transcript
  Returntype : arrayref of Bio::EnsEMBL::Gene
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_genes_by_operon_transcript_id {
	my ( $self, $operon_transcript_id ) = @_;
	my $helper =
	  Bio::EnsEMBL::Utils::SqlHelper->new( -DB_CONNECTION => $self->db->dbc() );

	my $gene_ids =
	  $helper->execute_simple(
		-SQL =>
'SELECT  gene_id FROM operon_transcript_gene tr WHERE  operon_transcript_id =?',
		-PARAMS => [$operon_transcript_id] );

	my $genes        = [];
	my $gene_adaptor = $self->db()->get_GeneAdaptor();
	for my $gene_id (@$gene_ids) {
		push @$genes, $gene_adaptor->fetch_by_dbID($gene_id);
	}
	return $genes;
}

=head2 fetch_all_by_gene

  Arg [1]    : Bio::EnsEMBL::Gene
  Example    : $ots = $ot_adaptor->fetch_all_by_gene($gene);
  Description: Retrieves all operon transcripts attached to a given gene
  Returntype : arrayref of Bio::EnsEMBL::OperonTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_all_by_gene {
	my ( $self, $gene ) = @_;
	assert_ref( $gene, 'Bio::EnsEMBL::Gene' );
	return $self->fetch_all_by_gene_id( $gene->dbID() );
}

=head2 fetch_all_by_gene_id

  Arg [1]    : Int id of Bio::EnsEMBL::Gene
  Example    : $ots = $ot_adaptor->fetch_all_by_gene($gene);
  Description: Retrieves all operon transcripts attached to a given gene
  Returntype : arrayref of Bio::EnsEMBL::OperonTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub fetch_all_by_gene_id {
	my ( $self, $gene_id ) = @_;
	my $helper =
	  Bio::EnsEMBL::Utils::SqlHelper->new( -DB_CONNECTION => $self->db->dbc() );

	my $ot_ids = $helper->execute_simple(
		-SQL =>
'SELECT operon_transcript_id FROM operon_transcript_gene tr WHERE gene_id =?',
		-PARAMS => [$gene_id] );

	my $ots = [];
	for my $ot_id (@$ot_ids) {
		push @$ots, $self->fetch_by_dbID($ot_id);
	}
	return $ots;
}

=head2 store

  Arg [1]    : Bio::EnsEMBL::OperonTranscript $gene
               The gene to store in the database
  Arg [2]    : ignore_release in xrefs [default 1] set to 0 to use release info 
               in external database references
  Example    : $gene_adaptor->store($gene);
  Description: Stores a gene in the database.
  Returntype : the database identifier (dbID) of the newly stored gene
  Exceptions : thrown if the $gene is not a Bio::EnsEMBL::OperonTranscript or if 
               $gene does not have an analysis object
  Caller     : general
  Status     : Stable

=cut

sub store {
	my ( $self, $operon_transcript, $operon_id ) = @_;

	assert_ref( $operon_transcript, 'Bio::EnsEMBL::OperonTranscript' );

	my $db = $self->db();

	if ( $operon_transcript->is_stored($db) ) {
		return $operon_transcript->dbID();
	}

	# ensure coords are correct before storing
	#$operon->recalculate_coordinates();

	my $seq_region_id;

	( $operon_transcript, $seq_region_id ) =
	  $self->_pre_store($operon_transcript);

	my $store_operon_transcript_sql = qq(
        INSERT INTO operon_transcript
           SET seq_region_id = ?,
               seq_region_start = ?,
               seq_region_end = ?,
               seq_region_strand = ?,
               display_label = ?,
               operon_id = ?
  );
	# column status is used from schema version 34 onwards (before it was
	# confidence)

	my $sth = $self->prepare($store_operon_transcript_sql);
	$sth->bind_param( 1, $seq_region_id,                      SQL_INTEGER );
	$sth->bind_param( 2, $operon_transcript->start(),         SQL_INTEGER );
	$sth->bind_param( 3, $operon_transcript->end(),           SQL_INTEGER );
	$sth->bind_param( 4, $operon_transcript->strand(),        SQL_TINYINT );
	$sth->bind_param( 5, $operon_transcript->display_label(), SQL_VARCHAR );
	$sth->bind_param( 6, $operon_id,                          SQL_INTEGER );

	$sth->execute();
	$sth->finish();

	my $operon_transcript_dbID = $sth->{'mysql_insertid'};

	# store stable ids if they are available
	if ( defined( $operon_transcript->stable_id() ) ) {
		my $statement = sprintf(
			    "INSERT INTO operon_transcript_stable_id SET "
			  . "operon_transcript_id = ?, "
			  . "stable_id = ?, "
			  . "version = ?, "
			  . "created_date = %s, "
			  . "modified_date = %s",
			$self->db()->dbc()->from_seconds_to_date(
											  $operon_transcript->created_date()
			),
			$self->db()->dbc()
			  ->from_seconds_to_date( $operon_transcript->modified_date() ) );

		$sth = $self->prepare($statement);
		$sth->bind_param( 1, $operon_transcript_dbID,         SQL_INTEGER );
		$sth->bind_param( 2, $operon_transcript->stable_id(), SQL_VARCHAR );
		$sth->bind_param( 3, $operon_transcript->version(),   SQL_INTEGER );
		$sth->execute();
		$sth->finish();
	}

	# store the dbentries associated with this gene
	my $dbEntryAdaptor = $db->get_DBEntryAdaptor();

	foreach my $dbe ( @{ $operon_transcript->get_all_DBEntries } ) {
		$dbEntryAdaptor->store( $dbe, $operon_transcript_dbID,
								"OperonTranscript" );
	}

	# store operon attributes if there are any
	my $attrs = $operon_transcript->get_all_Attributes();
	if ( $attrs && scalar @$attrs ) {
		my $attr_adaptor = $db->get_AttributeAdaptor();
		$attr_adaptor->store_on_OperonTranscript( $operon_transcript, $attrs );
	}

	# set the adaptor and dbID on the original passed in gene not the
	# transfered copy
	$operon_transcript->adaptor($self);
	$operon_transcript->dbID($operon_transcript_dbID);

	if ( defined $operon_transcript->{_gene_array} ) {
		$self->store_genes_on_OperonTranscript( $operon_transcript,
											$operon_transcript->{_gene_array} );
	}

	return $operon_transcript_dbID;
} ## end sub store

=head2 store_genes_on_OperonTranscript

  Arg [1]    : Bio::EnsEMBL::OperonTranscript $ot
               the operon_transcript to store genes on
  Arg [2]    : arrayref of Bio::EnsEMBL::Gene $gene
               the genes to store on operon transcript
  Example    : $ot_adaptor->store_genes_on_OperonTranscript(\@genes);
  Description: Associates genes with operon transcript
  Returntype : none
  Exceptions : throw on incorrect arguments 
               warning if operon_transcript is not stored in this database
  Caller     : general, store
  Status     : Stable

=cut

sub store_genes_on_OperonTranscript {
	my ( $self, $operon_transcript, $genes ) = @_;
	assert_ref( $operon_transcript, "Bio::EnsEMBL::OperonTranscript" );
	my $sth = $self->prepare(
'insert into operon_transcript_gene(operon_transcript_id,gene_id) values('
		  . $operon_transcript->dbID()
		  . ',?)' );
	for my $gene ( @{$genes} ) {
		assert_ref( $gene, "Bio::EnsEMBL::Gene" );
		$sth->bind_param( 1, $gene->dbID(), SQL_INTEGER );
		$sth->execute();
	}
	$sth->finish();
	return;
}

=head2 remove

  Arg [1]    : Bio::EnsEMBL::OperonTranscript $ot
               the operon_transcript to remove from the database
  Example    : $ot_adaptor->remove($ot);
  Description: Removes a operon transcript completely from the database.
  Returntype : none
  Exceptions : throw on incorrect arguments 
               warning if operon_transcript is not stored in this database
  Caller     : general
  Status     : Stable

=cut

sub remove {
	my $self              = shift;
	my $operon_transcript = shift;

	assert_ref( $operon_transcript, 'Bio::EnsEMBL::OperonTranscript' );

	if ( !$operon_transcript->is_stored( $self->db() ) ) {
		warning(   "Cannot remove operon transcript "
				 . $operon_transcript->dbID()
				 . ". Is not stored in "
				 . "this database." );
		return;
	}

	# remove all object xrefs associated with this gene

	my $dbe_adaptor = $self->db()->get_DBEntryAdaptor();
	foreach my $dbe ( @{ $operon_transcript->get_all_DBEntries() } ) {
		$dbe_adaptor->remove_from_object( $dbe, $operon_transcript,
										  'OperonTranscript' );
	}

#	# remove the attributes associated with this transcript
#	my $attrib_adaptor = $self->db->get_AttributeAdaptor;
#	$attrib_adaptor->remove_from_OperonTranscript($operon_transcript);

	# remove the stable identifier
	my $sth = $self->prepare(
"DELETE FROM operon_transcript_stable_id WHERE operon_transcript_id = ? " );
	$sth->bind_param( 1, $operon_transcript->dbID, SQL_INTEGER );
	$sth->execute();
	$sth->finish();

	# remove from the database
	$sth = $self->prepare(
			   "DELETE FROM operon_transcript WHERE operon_transcript_id = ? ");
	$sth->bind_param( 1, $operon_transcript->dbID, SQL_INTEGER );
	$sth->execute();
	$sth->finish();

	# unset the gene identifier and adaptor thereby flagging it as unstored

	$operon_transcript->dbID(undef);
	$operon_transcript->adaptor(undef);

	return;
} ## end sub remove

# _objs_from_sth

#  Arg [1]    : StatementHandle $sth
#  Arg [2]    : Bio::EnsEMBL::AssemblyMapper $mapper
#  Arg [3]    : Bio::EnsEMBL::Slice $dest_slice
#  Description: PROTECTED implementation of abstract superclass method.
#               responsible for the creation of OperonTranscripts
#  Returntype : listref of Bio::EnsEMBL::OperonTranscripts in target coordinate system
#  Exceptions : none
#  Caller     : internal
#  Status     : Stable

sub _objs_from_sth {
	my ( $self, $sth, $mapper, $dest_slice ) = @_;

	#
	# This code is ugly because an attempt has been made to remove as many
	# function calls as possible for speed purposes.  Thus many caches and
	# a fair bit of gymnastics is used.
	#

	my $sa = $self->db()->get_SliceAdaptor();
	#my $aa = $self->db->get_AnalysisAdaptor();

	my @operons;
	my %analysis_hash;
	my %slice_hash;
	my %sr_name_hash;
	my %sr_cs_hash;
	my ( $stable_id, $version, $created_date, $modified_date );

	my ( $operon_transcript_id, $seq_region_id,     $seq_region_start,
		 $seq_region_end,       $seq_region_strand, $display_label );

	$sth->bind_columns( \$operon_transcript_id, \$seq_region_id,
						\$seq_region_start,     \$seq_region_end,
						\$seq_region_strand,    \$display_label,
						\$stable_id,            \$version,
						\$created_date,         \$modified_date );

	my $asm_cs;
	my $cmp_cs;
	my $asm_cs_vers;
	my $asm_cs_name;
	my $cmp_cs_vers;
	my $cmp_cs_name;
	if ($mapper) {
		$asm_cs      = $mapper->assembled_CoordSystem();
		$cmp_cs      = $mapper->component_CoordSystem();
		$asm_cs_name = $asm_cs->name();
		$asm_cs_vers = $asm_cs->version();
		$cmp_cs_name = $cmp_cs->name();
		$cmp_cs_vers = $cmp_cs->version();
	}

	my $dest_slice_start;
	my $dest_slice_end;
	my $dest_slice_strand;
	my $dest_slice_length;
	my $dest_slice_sr_name;
	my $dest_slice_seq_region_id;
	if ($dest_slice) {
		$dest_slice_start         = $dest_slice->start();
		$dest_slice_end           = $dest_slice->end();
		$dest_slice_strand        = $dest_slice->strand();
		$dest_slice_length        = $dest_slice->length();
		$dest_slice_sr_name       = $dest_slice->seq_region_name();
		$dest_slice_seq_region_id = $dest_slice->get_seq_region_id();
	}

	my $count = 0;
  OPERON: while ( $sth->fetch() ) {
		$count++;
		#    #get the analysis object
		#    my $analysis = $analysis_hash{$analysis_id} ||=
		#      $aa->fetch_by_dbID($analysis_id);
		#need to get the internal_seq_region, if present
		$seq_region_id = $self->get_seq_region_id_internal($seq_region_id);
		#get the slice object
		my $slice = $slice_hash{ "ID:" . $seq_region_id };

		if ( !$slice ) {
			$slice = $sa->fetch_by_seq_region_id($seq_region_id);
			$slice_hash{ "ID:" . $seq_region_id } = $slice;
			$sr_name_hash{$seq_region_id}         = $slice->seq_region_name();
			$sr_cs_hash{$seq_region_id}           = $slice->coord_system();
		}

		my $sr_name = $sr_name_hash{$seq_region_id};
		my $sr_cs   = $sr_cs_hash{$seq_region_id};
		#
		# remap the feature coordinates to another coord system
		# if a mapper was provided
		#
		if ($mapper) {

			(  $seq_region_id,  $seq_region_start,
			   $seq_region_end, $seq_region_strand )
			  = $mapper->fastmap( $sr_name, $seq_region_start, $seq_region_end,
								  $seq_region_strand, $sr_cs );

			#skip features that map to gaps or coord system boundaries
			next OPERON if ( !defined($seq_region_id) );

			#get a slice in the coord system we just mapped to
			if ( $asm_cs == $sr_cs
				 || ( $cmp_cs != $sr_cs && $asm_cs->equals($sr_cs) ) )
			{
				$slice = $slice_hash{ "ID:" . $seq_region_id } ||=
				  $sa->fetch_by_seq_region_id($seq_region_id);
			} else {
				$slice = $slice_hash{ "ID:" . $seq_region_id } ||=
				  $sa->fetch_by_seq_region_id($seq_region_id);
			}
		}

	   #
	   # If a destination slice was provided convert the coords
	   # If the dest_slice starts at 1 and is foward strand, nothing needs doing
	   #
		if ($dest_slice) {
			if ( $dest_slice_start != 1 || $dest_slice_strand != 1 ) {
				if ( $dest_slice_strand == 1 ) {
					$seq_region_start =
					  $seq_region_start - $dest_slice_start + 1;
					$seq_region_end = $seq_region_end - $dest_slice_start + 1;
				} else {
					my $tmp_seq_region_start = $seq_region_start;
					$seq_region_start = $dest_slice_end - $seq_region_end + 1;
					$seq_region_end =
					  $dest_slice_end - $tmp_seq_region_start + 1;
					$seq_region_strand *= -1;
				}
			}

			#throw away features off the end of the requested slice
			if (    $seq_region_end < 1
				 || $seq_region_start > $dest_slice_length
				 || ( $dest_slice_seq_region_id != $seq_region_id ) )
			{
#	print STDERR "IGNORED DUE TO CUTOFF  $dest_slice_seq_region_id ne $seq_region_id . $sr_name\n";
				next OPERON;
			}
			$slice = $dest_slice;
		} ## end if ($dest_slice)

		push( @operons,
			  Bio::EnsEMBL::OperonTranscript->new(
									   -START         => $seq_region_start,
									   -END           => $seq_region_end,
									   -STRAND        => $seq_region_strand,
									   -SLICE         => $slice,
									   -DISPLAY_LABEL => $display_label,
									   -ADAPTOR       => $self,
									   -DBID          => $operon_transcript_id,
									   -STABLE_ID     => $stable_id,
									   -VERSION       => $version,
									   -CREATED_DATE  => $created_date || undef,
									   -MODIFIED_DATE => $modified_date || undef
			  ) );

	} ## end while ( $sth->fetch() )

	return \@operons;
} ## end sub _objs_from_sth

1;
