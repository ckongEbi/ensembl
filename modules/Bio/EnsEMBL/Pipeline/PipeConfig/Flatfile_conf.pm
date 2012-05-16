package Bio::EnsEMBL::Pipeline::PipeConfig::Flatfile_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

use Bio::EnsEMBL::ApiVersion qw/software_version/;

sub default_options {
    my ($self) = @_;
    
    return {
      # inherit other stuff from the base class
      %{ $self->SUPER::default_options() }, 
      
      ### OVERRIDE
      
      #'registry' => 'Reg.pm', # default option to refer to Reg.pm, should be full path
      #'base_path' => '', #where do you want your files
      
      ### Optional overrides        
      species => [],
      
      release => software_version(),

      types => [qw/embl genbank/],
      
      ### Defaults 
      
      pipeline_name => 'flatfile_dump_'.$self->o('release'),
      
      email => $self->o('ENV', 'USER').'@sanger.ac.uk',
      
    };
}

sub pipeline_create_commands {
    my ($self) = @_;
    return [
      # inheriting database and hive tables' creation
      @{$self->SUPER::pipeline_create_commands}, 
    ];
}

## See diagram for pipeline structure 
sub pipeline_analyses {
    my ($self) = @_;
    
    return [
    
      {
        -logic_name => 'ScheduleSpecies',
        -module     => 'Bio::EnsEMBL::Pipeline::SpeciesFactory',
        -parameters => {
          species => $self->o('species')
        },
        -input_ids  => [ {} ],
        -flow_into  => {
          1 => 'Notify',
          2 => ['DumpTypeFactory'],
        },
      },
      
      ######### DUMPING DATA
      
      {
        -logic_name => 'DumpTypeFactory',
        -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
        -parameters => {
          column_names => ['type'],
          inputlist => $self->o('types'),
          input_id => { species => '#species#', type => '#type#' },
          fan_branch_code => 2
        },
        -flow_into  => { 2 => ['DumpFlatfile', 'ChecksumGenerator'] },
      },
      
      {
        -logic_name => 'DumpFlatfile',
        -module     => 'Bio::EnsEMBL::Pipeline::Flatfile::DumpFile',
        -max_retry_count  => 1,
        -hive_capacity    => 10,
      },
      
      ####### CHECKSUMMING
      
      {
        -logic_name => 'ChecksumGenerator',
        -module     => 'Bio::EnsEMBL::Pipeline::Flatfile::ChecksumGenerator',
        -wait_for   => [qw/DumpFlatfile/],
        -hive_capacity => 10, 
      },
      
      ####### NOTIFICATION
      
      {
        -logic_name => 'Notify',
        -module     => 'Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail',
        -parameters => {
          email   => $self->o('email'),
          subject => $self->o('pipeline_name').' has finished',
          text    => 'Your pipeline has finished. Please consult the hive output'
        },
        -wait_for   => ['ChecksumGenerator'],
      }
    
    ];
}

sub pipeline_wide_parameters {
    my ($self) = @_;
    
    return {
        %{ $self->SUPER::pipeline_wide_parameters() },  # inherit other stuff from the base class
        base_path => $self->o('base_path'), 
        db_types => $self->o('db_types'),
        release => $self->o('release'),
    };
}

# override the default method, to force an automatic loading of the registry in all workers
sub beekeeper_extra_cmdline_options {
    my $self = shift;
    return "-reg_conf ".$self->o("registry");
}

sub resource_classes {
    my $self = shift;
    return {
      0 => { -desc => 'default', 'LSF' => '-q normal -M4000000 -R"select[mem>4000] rusage[mem=4000]"'},
    }
}

1;