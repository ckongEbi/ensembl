# Schema for internal-external database mappings (xrefs)


################################################################################
#
# General external annotation.

CREATE TABLE xref (

  xref_id                     int unsigned not null auto_increment,
  accession                   varchar(255) not null,
  label                       varchar(255),
  source_id                   int unsigned not null,
  species_id                  int unsigned not null,

  PRIMARY KEY (xref_id)

);

################################################################################

CREATE TABLE primary_xref (

  xref_id                     int unsigned not null,
  sequence                    mediumtext,
  sequence_type               enum('dna','peptide'),
  status                      enum('experimental','predicted'),
  source_id                   int unsigned not null,

  PRIMARY KEY (xref_id)

);

################################################################################

CREATE TABLE dependent_xref (

  master_xref_id              int unsigned not null,
  dependent_xref_id           int unsigned not null,
  linkage_annotation          varchar(255),
  source_id                   int unsigned not null,

  KEY master_idx(master_xref_id),
  KEY dependent_idx(dependent_xref_id)

);

################################################################################

CREATE TABLE synonym (

  xref_id                     int unsigned not null,
  synonym_xref_id             int unsigned not null,
  source_id                   int unsigned not null,

  KEY xref_idx(xref_id)

);

################################################################################

CREATE TABLE source (

  source_id                   int unsigned not null auto_increment,
  name                        varchar(255) not null,
  url                         varchar(255),
  file_modified_date          timestamp(14) not null,
  upload_date                 timestamp(14) not null,
  release                     varchar(255),

  PRIMARY KEY (source_id),
  KEY name_idx(name) 

);

################################################################################

CREATE TABLE species (

  species_id                  int unsigned not null auto_increment,
  name                        varchar(255) not null,

  PRIMARY KEY(species_id),
  KEY name_idx(name)

);

################################################################################

CREATE TABLE direct_xref (

  general_xref_id             int unsigned not null,
  ensembl_stable_id           varchar(255),
  type                        enum('gene','transcript','translation'),
  linkage_xref                varchar(255),

  KEY primary_idx(general_xref_id),
  KEY ensembl_idx(ensembl_stable_id)

);

################################################################################

