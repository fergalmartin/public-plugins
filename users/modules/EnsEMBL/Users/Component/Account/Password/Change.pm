package EnsEMBL::Users::Component::Account::Password::Change;

### Create a form for the user to be able to change his password
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return shift->hub->user ? 'Change Password' : 'Reset Password';
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $content   = $self->wrapper_div;
  my $form      = $content->append_child($self->new_form({'action' => $hub->url({qw(action Password function Save)})}));

  my $user      = $hub->user;
  my $login     = $user ? $user->rose_object->get_local_login : $object->get_login_from_url_code;

  # If no login object found - user manually changed the url
  return $self->render_message($object->get_message_code('MESSAGE_UNKNOWN_ERROR'), {'error' => 1}) unless $login;

  $form->add_field({'type' => 'noedit', 'name' => 'email', 'label' => 'Login email', 'no_input' => 1, 'value' => $login->identity });

  if ($user) {
    $form->add_field({'type' => 'password', 'name' => 'password', 'label' => 'Current password', 'required' => 1});
  } else {
    $form->add_hidden({'name' => 'code', 'value' => $login->get_url_code });
  }

  $form->add_field({'type' => 'password', 'name' => 'new_password_1', 'label' => 'New password',          'required' => 1,  'notes' => 'at least 6 characters'});
  $form->add_field({'type' => 'password', 'name' => 'new_password_2', 'label' => 'Confirm new password',  'required' => 1});
  $form->add_button({'type' => 'Submit',  'name' => 'submit',   'value' => $user ? 'Change' : 'Reset', 'class'  => 'modal_link'});

  return $content->render;
}

1;