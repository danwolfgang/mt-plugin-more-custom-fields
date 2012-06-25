# This is a common module for the Selected Entries, Selected Pages, and
# Selected Entries or Pages Custom Fields. Since they are all so similar they
# can all make use of some of the same code.
package MoreCustomFields::SelectedObject;

use strict;
use warnings;

use MT::Util
  qw( relative_date format_ts );

# This creates the popup dialog that shows the listing of Entries/Pages that
# can be selected.
sub list_objects {
    my ($arg_ref)  = @_;
    my $app        = $arg_ref->{app};
    my $blog_ids   = $arg_ref->{blog_ids};
    my $type       = $arg_ref->{type};
    my $edit_field = $arg_ref->{edit_field};
    my $search     = $arg_ref->{search} || '';

    die $app->error('Required object type and edit field values missing!')
        unless $type && $edit_field;

    my $plugin = MT->component('MoreCustomFields');

    my %terms = (
         status => MT::Entry->RELEASE(), # Published
    );

    my @blog_ids;
    if ($blog_ids eq 'all') {
        # @blog_ids should stay empty so all blogs are loaded.
    }
    else {
        # Turn this into an array so that all specified blogs can be loaded.
        @blog_ids = split(/,/, $blog_ids);
        $terms{blog_id} = [@blog_ids];
    }

    my %args = (
        sort      => 'authored_on',
        direction => 'descend',
    );

    my $tmpl = $plugin->load_tmpl('entry_list.mtml');

    # For some reason the 'page' _type doesn't get set/picked up for
    # searches, so just set it here.
    $app->param('_type', $type);

    return $app->listing({
        type     => $type,
        template => $tmpl,
        params   => {
            panel_searchable => 1,
            # edit_blog_id     => $blog_ids,
            edit_field       => $edit_field,
            search           => $search,
            blog_id          => $blog_ids,
            type             => $type,
        },
        code => sub {
            my ($obj, $row) = @_;
            $row->{'status_' . lc MT::Entry::status_text($obj->status)} = 1;

            $row->{entry_permalink} = $obj->permalink
                if $obj->status == MT::Entry->RELEASE();

            if (my $ts = $obj->authored_on) {
                my $date_format = MT::App::CMS->LISTING_DATE_FORMAT();
                my $datetime_format = MT::App::CMS->LISTING_DATETIME_FORMAT();
                $row->{created_on_formatted} = format_ts($date_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_time_formatted} = format_ts($datetime_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_relative} = relative_date($ts, time, $obj->blog);
            }

            my $author = MT->model('author')->load( $obj->author_id );
            $row->{author_name} = $author ? $author->nickname : '';

            return $row;
        },
        terms => \%terms,
        args  => \%args,
        limit => 10,
    });
}

# When an Entry or Page has been chosen from the listing popup, insert it into
# the Edit Entry/Edit Page screen.
sub select_object {
    my $app    = shift;
    my $plugin = MT->component('MoreCustomFields');

    my $obj_id = $app->param('id')
        or die $app->errtrans('Object ID not specified.');
    
    my $type = $app->param('_type')
        or die $app->errtrans('Object type not specified.');

    my $obj = MT->model($type)->load($obj_id)
        or die $app->errtrans('No [_1] #[_2].', $type, $obj_id);

    my $edit_field = $app->param('edit_field')
        or die $app->errtrans('No edit_field');

    my $tmpl = $plugin->load_tmpl('select_entry.mtml', {
        obj_id      => $obj->id,
        obj_title   => $obj->title,
        obj_blog_id => $obj->blog_id,
        edit_field  => $edit_field,
    });

    return $tmpl;
}

1;

__END__
