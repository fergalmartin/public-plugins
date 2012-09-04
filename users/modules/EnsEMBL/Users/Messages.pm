package EnsEMBL::Users::Messages;

### @usages
### use EnsEMBL::Users::Messages qw(ALL);                     # is same as use EnsEMBL::Users::Messages; # will include all the message constants, but not the get_message method
### use EnsEMBL::Users::Messages qw(get_message);             # will only include the get_message method, no message constants
### use EnsEMBL::Users::Messages qw(ALL get_message);         # will include all message constants and the get_message method
### use EnsEMBL::Users::Messages qw(MESSAGE_PASSWORD_WRONG);  # will only include only the specified message constant

use strict;
use warnings;

use HTML::Entities qw(encode_entities);
use Digest::MD5 qw(md5_hex);

my %MESSAGES = (
  MESSAGE_OPENID_CANCELLED      => sub { sprintf('Your request to login via %s was cancelled. Please try again, or use one of the alternative login options below.', encode_entities($_[0]->param('provider') || 'OpenID')) },
  MESSAGE_OPENID_INVALID        => sub { '_message__OPENID_INVALID' },
  MESSAGE_OPENID_SETUP_NEEDED   => sub { '_message__OPENID_SETUP_NEEDED' },
  MESSAGE_OPENID_ERROR          => sub { sprintf('<p>An error happenned while making OpenID request. Please use an alternative login option.</p><p>Error summary: %s</p>', encode_entities($_[0]->param('oerr') || '')) },
  MESSAGE_OPENID_EMAIL_MISSING  => sub { '_message__OPENID_EMAIL_MISSING' },
  MESSAGE_EMAIL_NOT_FOUND       => sub { sprintf('The email address provided is not recognised. Please try again with a different email for <a href="%s">register</a> here if you are a new user.', encode_entities($_[0]->url({qw(type Account action Register)}))) },
  MESSAGE_PASSWORD_WRONG        => sub { 'The password provided is invalid. Please try again.' },
  MESSAGE_PASSWORD_INVALID      => sub { 'Password needs to be atleast 6 characters long.' },
  MESSAGE_PASSWORD_MISMATCH     => sub { 'The passwords do not match. Please try again.' },
  MESSAGE_PASSWORD_CHANGED      => sub { 'New password has been saved successfully. Please login with the new password.' },
  MESSAGE_ALREADY_REGISTERED    => sub { sprintf('The email address provided seems to be already registered. Please try to login with the email, or request to <a href="%s">retrieve your password</a> if you have lost one.', $_[0]->url({'action' => 'Password', 'function' => 'Lost', 'email' => $_[0]->param('email')})) },
  MESSAGE_VERIFICATION_FAILED   => sub { 'The email address could not be verified.' },
  MESSAGE_VERIFICATION_PENDING  => sub { '_message__VERIFICATION_PENDING' },
  MESSAGE_EMAIL_INVALID         => sub { 'Please enter a valid email address' },
  MESSAGE_EMAILS_INVALID        => sub { sprintf('Invalid email address: %s', encode_entities($_[0]->param('invalids') || '')) },
  MESSAGE_NAME_MISSING          => sub { 'Please provide a name' },
  MESSAGE_ACCOUNT_BLOCKED       => sub { 'Your account seems to be blocked. Please contact the helpdesk in case you need any help.' },
  MESSAGE_VERIFICATION_SENT     => sub { sprintf(q(A verification email has been sent to the email address '%s'. Please go to your inbox and click on the link provided in the email.), encode_entities($_[0]->param('email'))) },
  MESSAGE_PASSWORD_EMAIL_SENT   => sub { sprintf(q(An email has been sent to the email address '%s'. Please go to your inbox and follow the instructions to reset your password provided in the email.), encode_entities($_[0]->param('email'))) },
  MESSAGE_EMAIL_CHANGED         => sub { sprintf(q(You email address on our records has been successfully changed. Please <a href="%s">%s</a> to continue.), $_[0]->url({'action' => 'Preferences'}), $_[0]->user ? 'click here' : 'login') },
  MESSAGE_CANT_DELETE_LOGIN     => sub { 'You can not delete the only login option you have to access your account.' },
  MESSAGE_GROUP_NOT_FOUND       => sub { 'Sorry, we could not find the specified group. Either the group does not exist or is inactive or is inaccessible to you for the action selected.' },
  MESSAGE_GROUP_INVITATION_SENT => sub { sprintf(q{Invitation for the group sent successfully to the following email(s): %s}, encode_entities($_[0]->param('emails'))) },
  MESSAGE_CANT_DEMOTE_ADMIN     => sub { 'Sorry, you can not demote yourself as you seem to be the only administrator of this group.' },
  MESSAGE_BOOKMARK_NOT_FOUND    => sub { 'Sorry, we could not find the specified bookmark.' },
  MESSAGE_CANT_DELETE_BOOKMARK  => sub { 'You do not seem to have the right to delete this bookmark.' },
  MESSAGE_NO_EXISTING_ACCOUNT   => sub { sprintf(q(No existing account was found for the email address provided. Please verify the email address again, or to create a new account, please <a href="%s">click here</a>), $_[0]->url({'action' => 'OpenID', 'function' => 'Register', 'code' => $_[0]->param('code')})) },
  MESSAGE_URL_EXPIRED           => sub { 'The link you clicked to reach here has been expired.' },
  MESSAGE_UNKNOWN_ERROR         => sub { 'An unknown error occurred. Please try again or contact the help desk.' }
);

my %CODES = map { $_ => substr(md5_hex($_), 0, 8) } keys %MESSAGES;

sub import {
  my $class     = shift;
  my $caller    = caller;
  my %includes  = map { $_ => 1 } @_;

  {
    no strict qw(refs);

    if ($includes{'get_message'}) {
      *{"${caller}::get_message"} = sub {
        my ($code, $hub) = @_;
        my $constant = { reverse %CODES }->{$code || ''};
        return $MESSAGES{$constant || 'MESSAGE_UNKNOWN_ERROR'}->($hub);
      };
    }

    foreach my $message_constant (grep { !@_ || $includes{'ALL'} || $includes{$_} } keys %MESSAGES) {
      *{"${caller}::${message_constant}"} = sub { return $CODES{$message_constant}; };
    }
  }
}

1;
