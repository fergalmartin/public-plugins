=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Selenium::Test;

use strict;
use LWP::UserAgent;
use Time::HiRes;
use EnsEMBL::Selenium;
use Test::Exception;
use Test::More "no_plan";

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::DBSQL::WebsiteAdaptor;

my $DEFAULTS = {timeout => 50000};
my $TESTMORE_OUTPUT;

sub new {
  my($class, %args) = @_;

  die 'Must supply a url' unless $args{url};
  
  my $self = {
    _url      => $args{url},
    _host     => $args{host},
    _port     => $args{port},
    _browser  => $args{browser},
    _ua       => $args{ua} || LWP::UserAgent->new(keep_alive => 5, env_proxy => 1),
    _conf     => {},
    _verbose  => $args{verbose},
    _species  => $args{species},
  };
    
  if (ref $args{conf} eq 'HASH') {
    foreach my $key (keys %{$args{conf}}) {
      $self->{_conf}->{$key} = $args{conf}->{$key};
    }
  }
  
  $self->{_sel} = EnsEMBL::Selenium->new( 
    _ua         => $self->{_ua},
    host        => $self->{_host},
    port        => $self->{_port},
    browser     => $self->{_browser},
    browser_url => $self->{_url},
  );

  bless $self, $class;
  
  $self->sel->set_timeout($self->conf('timeout'));
    
  # redirect Test::More output unless we're in verbose mode
  Test::More->builder->output(\$TESTMORE_OUTPUT) unless ($self->verbose);
    
  return $self;
}

sub url     {$_[0]->{_url}};
sub host    {$_[0]->{_host}};
sub port    {$_[0]->{_port}};
sub browser {$_[0]->{_browser}};
sub ua      {$_[0]->{_ua}};
sub sel     {$_[0]->{_sel}};
sub verbose {$_[0]->{_verbose}};
sub species {$_[0]->{_species}};


sub set_default {
  my ($self, $key, $value) = @_;
  $DEFAULTS->{$key} = $value;
}

sub conf {
  my ($self, $key) = @_;
  return $self->{_conf}->{$key} || $DEFAULTS->{$key};
}

sub testmore_output {
  # test builder output (this will be empty if we are in verbose mode)
  return $TESTMORE_OUTPUT;
}

#Getting the database information from the hub
sub database {
 my ($self, $db, $species) = @_;
 
 my $hub  = EnsEMBL::Web::Hub->new; 
 my $database = $hub->database($db, $species);
 
 return $database;
}

#getting species def from hub, can be used to check for species name, release version and other web related text
sub get_species_def {
  my $self = shift;
  my $hub = EnsEMBL::Web::Hub->new;
  my $SD = $hub->species_defs; 
 
  return $SD;
}

#Gets the current URL in the window (to know which page is being tested)
sub get_location {
  my $self = shift;
  
  my $location = $self->sel->get_location();
  return $location;
}

#CHECK IF THE SITE IS UP...EXIT IF NOT
sub check_website {
  my $self = shift;
  
  my $url = $self->url;
  $self->sel->open("/");
  if ($self->sel->get_title eq "The Ensembl Genome Browser (development)") {
    print"\n$url IS DOWN!!!!!\n";
    exit;
  }
}

#setting the species in conf
sub set_species {
 my ($self, $species) = @_; 
 $self->{'_species'} = $species;  
}

# Because the test are being run on a useast machine accessing www on this machine will cause a redirect to useast and hence stopping the redirect, shouldn't be a problem to test useast.ensembl.org as the link won't be here
sub no_mirrors_redirect {
  my $self = shift;
  
  if($self->sel->is_text_present("You are being redirected to")) {
    print"Click link to stop redirect to mirrors...\n";
    $self->sel->open("/");
    $self->sel->click("link=here")
    and $self->sel->pause(5000);
  }
}
1;
