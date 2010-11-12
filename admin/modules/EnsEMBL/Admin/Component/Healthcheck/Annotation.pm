package EnsEMBL::Admin::Component::Healthcheck::Annotation;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

use EnsEMBL::Web::Form;

sub caption {
  return 'Annotation';
}

sub content {
  my $self = shift;
  
  my $hub           = $self->hub;
  my $referrer      = $hub->referer->{'uri'};
  my $report_id     = $hub->param('rid') || 0;
  my $db_interface  = $self->object;
  
  return '<p class="hc_p">No report found to annotate. (Missing report id)</p>' unless $report_id;

  $report_id  = [ split ',', $report_id ]; #for multiple reports
  my $reports = $db_interface->data_interface('Report')->fetch_by_id($report_id, 1); #fetch_by_id(ArrayRef $report_id, Boolean $failed_only)

  return '<p class="hc_p">No report found to annotate. (Invalid report id)</p>' unless scalar $reports;
  
  my $user_db_interface = $db_interface->data_interface('User');
  my $current_user      = $user_db_interface->fetch_by_id($hub->user->user_id)->[0];

  my $heading       = 'Add annotation';
  my $label_done_by = 'Added by';
  my $comment       = {
    'text'        => '',
    'action'      => '',
    'created_by'  => '',
  };
  
  my $annotation;
  if (scalar @$reports == 1 && ($annotation = $reports->[0]->annotation)) {
    $comment->{'text'}        = $annotation->comment;
    $comment->{'action'}      = $annotation->action;
    $comment->{'created_by'}  = $user_db_interface->fetch_by_id($annotation->created_by)->[0]->name if $annotation->created_by;
    $heading                  = 'Edit annotation';
    $label_done_by            = 'Edited by';
  }

  my $html = '<h4>Report'.(scalar @$reports > 1 ? 's' : '').'</h4><ul>';
  my $rid  = []; #ArrayRef of report ids to be passed as POST param
  
  for (@$reports) {
    $html .= '<li><b>'.$_->database_name.' ('.$_->testcase.')</b>: '
                .join (', ', split (/,\s?/, $_->text))     #for wrapping the text ("a,b,c,d" converted to "a, b, c, d")
                .'</li>' if $_->report_id;
    push @$rid, $_->report_id if $_->report_id;
  }
  $html   .= '</ul>';
  
  my $form = EnsEMBL::Web::Form->new('annotation', '/Healthcheck/AnnotationSave', 'post');
  
  $form->add_fieldset('legend' => $heading);
  
  my $options = []; #options for action select box
  my $actions = $self->annotation_action('all');
  for (keys %$actions) {
    push @$options, {'value' => $_, 'name' => $actions->{ $_ }};
  }
  
  $form->add_element(
    'label'     => 'Action',
    'name'      => 'action',
    'value'     => $self->annotation_action($comment->{'action'})->{'value'},
    'type'      => 'DropDown',
    'select'    => 'select',
    'values'    => $options
  );            
                
  $form->add_element(
    'label'     => 'Comment',
    'type'      => 'String',
    'size'      => '60',
    'name'      => 'comment',
    'value'     => $comment->{'text'}
  );
                  
  $form->add_element(
    'label'     => 'Added by',
    'type'      => 'NoEdit',
    'name'      => 'added_by_name',
    'value'     => $comment->{'created_by'}
  ) if $comment->{'created_by'} ne '';

  $form->add_element(
    'label'     => $label_done_by,
    'type'      => 'NoEdit',
    'name'      => 'user_name',
    'value'     => $current_user->name
  );
                
  $form->add_element(
    'type'      =>  'Submit',
    'value'     =>  'Save',
    'name'      =>  'submit'
  );
  
  $form->add_hidden({
    'rid'       =>  join (',', @$rid),
    'referrer'  =>  $referrer,
  });
  
  return $html.$form->render;
}

1;