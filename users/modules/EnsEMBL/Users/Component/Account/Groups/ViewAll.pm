package EnsEMBL::Users::Component::Account::Groups::ViewAll;

### Page for a logged in user to view all of his groups
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $user        = $hub->user->rose_object;
  my $memberships = $user->memberships;
  my $subsections = [
    $self->link_create_new_group,
    $self->link_join_existing_group
  ];

  if (@$memberships) {
    my $table = $self->new_table([
      {'title' => 'Group Name',         'key' => 'name',    'width' => '30%'},
      {'title' => 'Description',        'key' => 'desc',    'width' => '50%'},
      {'title' => 'Number of members',  'key' => 'number',  'width' => '10%', 'class' => 'sort_numeric' },
      {'title' => '',                   'key' => 'edit',    'width' => '10%', 'class' => 'sort_html'    },
    ], [], {'data_table' => 'no_col_toggle', 'exportable' => 0});

    for (sort {uc $a->group->name cmp uc $b->group->name} @$memberships) {
      my $is_pending_request = $_->is_pending_request;
      next unless $_->is_active || $is_pending_request;
      my $group = $_->group;
      $table->add_row({
        'name'    => $self->html_encode($group->name),
        'number'  => $group->memberships_count('query' => ['status' => 'active', 'member_status' => 'active']),
        'desc'    => $self->html_encode($group->blurb),
        'edit'    => $self->js_link({
          $is_pending_request ? (
            'href'    => {'action' => 'Membership', 'function' => 'Unjoin', 'id' => $_->group_member_id},
            'caption' => 'Delete request',
            'target'  => 'none',
          ) : (
            'href'    => {'action' => 'Groups', 'function' => 'View', 'id' => $_->group_id},
            'caption' => $_->level eq 'member' ? 'View' : 'Moderate',
            'target'  => 'page',
          ),
          'inline'  => 1
        })
      });
    }
    unshift @$subsections, $table->render;

  } else {
    unshift @$subsections, q(<p>You are not a member of any group</p>);
  }

  return $self->js_section({
    'id'          => 'my_groups',
    'refresh_url' => {'action' => 'Groups', 'function' => ''},
    'heading'     => 'Groups',
    'subsections' => $subsections
  });
}

1;