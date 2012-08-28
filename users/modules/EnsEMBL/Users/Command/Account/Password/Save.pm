package EnsEMBL::Users::Command::Account::Password::Save;

### Command module that sets/changes the login password
### This modules is used when
###  1. the user registers with new password after submitting the "confirm email" form
###  2. the user submits the "change password" form
###  3. the user submits the "reset password" form after he clicks on the link in the 'retrieve passord' email
### @author hr5

### TODO - any alternative to using referer?

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;

  my $user    = $hub->user;
  my $login   = $user ? $user->rose_object->get_local_login : $object->fetch_login_from_url_code;
  my $referer = $hub->referer;

  # If no login object found - user manually changed the url
  return $self->redirect_message('MESSAGE_UNKNOWN_ERROR', {'error' => 1}) unless $login && $referer->{'ENSEMBL_TYPE'} eq 'Account';

  # If logged-in user trying to change password, and typed in a wrong current password
  return $self->ajax_redirect($hub->url({'action' => $referer->{'ENSEMBL_ACTION'}, 'function' => $referer->{'ENSEMBL_FUNCTION'}, 'err' => $object->get_message_code('MESSAGE_PASSWORD_WRONG')})) if $user && !$login->verify_password($hub->param('password'));

  # Validation
  my $fields = $self->validate_fields({'password' => $hub->param('new_password_1') || '', 'confirm_password' => $hub->param('new_password_2') || ''});

  return $self->ajax_redirect($hub->url({
    'action'    => $referer->{'ENSEMBL_ACTION'},
    'function'  => $referer->{'ENSEMBL_FUNCTION'},
    'err'       => $object->get_message_code($fields->{'invalid'} eq 'password' ? 'MESSAGE_PASSWORD_INVALID' : 'MESSAGE_PASSWORD_MISMATCH'),
    $user ? () : (
      'code'    => $login->get_url_code
    )
  })) if $fields->{'invalid'};

  # If all ok, change/set the password
  $login->set_password($fields->{'password'});

  # If reached here after clicking a link in the email address verification email, we need to activate the login account
  if ($hub->action eq 'Confirmed') {
    $object->activate_user_login($login);
    return $self->redirect_after_login($login->user);

  # For a password change/reset request
  } else {
    $login->reset_salt_and_save;
    return $self->ajax_redirect($hub->url({'action' => 'Preferences'}));
  }
}

1;